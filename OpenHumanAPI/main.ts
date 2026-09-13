import { randomUUID } from "node:crypto";
import {
  ChatRequest,
  Choice,
  Completion,
  messageToString,
  ToolCall,
} from "./data.ts";
import { promptMultiLine, unixTimestampNow } from "./utils.ts";

const API_KEY = [
  "sk-CrazyThursdayGiveMe50Yuan",
  "sk-111",
];

interface QueuedRequest {
  data: ChatRequest;
  resolve: (choice: Choice) => void;
  reject: (reason?: string) => void;
}

class RequestQueue {
  public queue: QueuedRequest[];
  waiting: () => void;

  constructor() {
    this.queue = [];
    this.waiting = () => {};
  }

  public push(qr: QueuedRequest) {
    this.queue.push(qr);
    this.waiting();
  }

  public async pop(): Promise<QueuedRequest> {
    while (true) {
      const qr = this.queue.shift();
      if (qr !== undefined) return qr;
      // 当 push 被调用的时候此Promise会完成
      await new Promise<void>((resolve, _) => {
        this.waiting = resolve;
      });
    }
  }
}

const requests = new RequestQueue();

function validateApiKey(headers: Headers): boolean {
  const auth = headers.get("authorization")?.replace(/^Bearer/, "").trim() ??
    headers.get("Authentication")?.replace(/^Bearer/, "").trim() ??
    "sk-or-not";
  return API_KEY.includes(auth);
}

export async function handler(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const path = url.pathname.replace("/v1", "");
  const modelName = Deno.env.get("USER") ?? "maybe-a-model";

  // 固定的回复内容{{{
  if (path === "/api/models") {
    return Response.json({
      total_count: 1,
      links: { next: null },
      object: "list",
      data: [
        {
          id: modelName,
          object: "model",
          created: unixTimestampNow(),
          owned_by: "Yan",
        },
      ],
    });
  }
  if (path === "/api/responses") {
    if (!validateApiKey(req.headers)) {
      return new Response("Authentication Fails.", { status: 401 });
    }
    return Response.json({
      id: "resp_67676767676767676767676767676767",
      create_at: unixTimestampNow(),
      completed_at: unixTimestampNow(),
      object: "response",
      model: modelName,
      output: [
        {
          type: "message",
          id: "msg_b4fcb87feaf7425f946c38074d09eab8",
          status: "completed",
          role: "assistant",
          content: [{
            type: "output_text",
            text:
              "Well we just **do not** support response api so... you may want to use `/chat/completions`, right?",
          }],
        },
      ],
      usage: {
        input_tokens: 27,
        output_tokens: 27,
        total_tokens: 2727,
      },
    });
  } // }}}

  if (path === "/api/chat/completions") {
    if (!validateApiKey(req.headers)) {
      return new Response("Authentication Fails.", { status: 401 });
    }
    // 好的这回该关心输入内容了
    const chat = await req.json() as ChatRequest;
    // 似乎也不是很关心……算了不管
    try {
      const choice = await new Promise<Choice>((resolve, reject) => {
        const timeout = setTimeout(
          () => reject("服务器繁忙请稍后重试喵"),
          120_000,
        );
        requests.push({
          data: chat,
          resolve: (c) => {
            clearTimeout(timeout);
            resolve(c);
          },
          reject,
        });
      });
      // 假装计算一下token
      const prompt_tokens = Math.sumPrecise(
        chat.messages.map((m) => m.content.length),
      );
      const completion_tokens = choice.message.content?.length ?? 27;
      // 回复体
      if (chat.stream) {
        // 假装自己是流式回复……
        const completion = {
          id: randomUUID().toString(),
          object: "chat.completion",
          created: unixTimestampNow(),
          model: modelName,
          system_fingerprint: "喵喵喵喵喵喵喵喵",
          choices: [{
            ...choice,
            delta: choice.message,
          }],
          usage: {
            prompt_tokens,
            completion_tokens,
            total_tokens: prompt_tokens + completion_tokens,
          },
        };
        return new Response(
          `data: ${JSON.stringify(completion)}\n\ndata: [DONE]`,
          {
            headers: {
              "content-type": "text/event-stream",
            },
          },
        );
      }
      const completion: Completion = {
        id: randomUUID().toString(),
        object: "chat.completion",
        created: unixTimestampNow(),
        model: "Yan",
        system_fingerprint: "喵喵喵喵喵喵喵喵",
        choices: [choice],
        usage: {
          prompt_tokens,
          completion_tokens,
          total_tokens: prompt_tokens + completion_tokens,
        },
      };
      console.log(completion);
      return Response.json(completion, {
        headers: {
          "Content-Type": "application/json",
        },
      });
    } catch (e) {
      return Response.json({
        error: {
          message: e,
          type: "non_catgirl_error",
          param: null,
          code: "invalid_meow",
        },
      }, {
        status: 503,
      });
    }
  }

  if (url.pathname === "/api") {
    return Response.json({
      message: "Hello, world!",
      time: new Date().toISOString(),
    });
  }

  console.log(req);

  return new Response("Oops.");
}

if (!Deno.stdin.isTerminal()) {
  console.error("要处理终端输入的啦……必须在终端里使用喵");
  Deno.exit(1);
}

// 启动监听
Deno.serve({ port: 60251 }, handler);
console.log("监听已启动喵！请狠狠地使用……使用自己喵？");

while (true) {
  // 在终端请求消息处理
  const request = await requests.pop();
  console.log(
    "|-----------------------------<+>-----------------------------|",
  );
  console.log("新请求喵:");
  console.log(`接收时间: ${new Date()}`);
  let reply = "";
  const toolcalls: ToolCall[] = [];

  // 输入循环
  while (true) {
    console.log("|===============");
    console.log("当前回复:\n" + reply);
    console.log(
      `当前工具调用: [${toolcalls.map((t) => t.function.name).join(", ")}]`,
    );
    console.log("================");
    console.log(
      "1. 查看消息列表 - 2. 查看工具列表 - 3. 回复 - 4. 添加工具调用 - 0. 发送回复",
    );
    const input = prompt(": ")?.trim() ??
      "";
    try {
      if (input.startsWith("1")) {
        for (const msg of request.data.messages) {
          console.log(messageToString(msg));
        }
        console.log();
      }
      if (input.startsWith("2")) {
        if (request.data.tools) {
          if (input.split(/\s+/)[1]) {
            const tool = request.data.tools.find((tool) =>
              tool.function.name == input.split(/\s+/)[1]
            );
            if (tool) {
              console.log(
                `「${tool.function.name}」\n${tool.function.description}\n\nSchema:\n`,
                tool.function.parameters,
              );
            } else {
              console.log("没有符合名字的工具");
            }
          } else {
            // 显示简略工具列表
            for (const tool of request.data.tools) {
              if (!tool.function) continue;
              console.log("+--------------");
              console.log(
                `「${tool.function.name}」:\n${
                  tool.function.description.split("\n")[0]
                }`,
              );
            }
            console.log(
              "::: 提示: 你可以使用 2 <工具名> 查看详细的描述，以及指令参数结构",
            );
          }
        } else {
          console.log("没有可用的工具喵");
        }
      }
      if (input.startsWith("3")) {
        console.log("以空行结束回复输入:");
        const input = promptMultiLine();
        reply += input + "\n";
      }
      if (input.startsWith("4")) {
        const fName = prompt("要调用的函数名: ");
        if (fName === null || fName.length === 0) continue;
        console.log("输入json参数(以空行结束):");
        let fArgs = undefined;
        while (fArgs === undefined) {
          try {
            const input = promptMultiLine();
            JSON.parse(input);
            fArgs = input;
          } catch (e) {
            console.log("输入的json结构错误: " + e);
            console.log('如果不传参数，使用"{}"');
          }
        }
        toolcalls.push({
          id: randomUUID().toString(),
          type: "function",
          function: { name: fName, arguments: fArgs },
        });
      }
    } catch (e) {
      console.error(`Error: ${e}`);
    }
    if (input.startsWith("0")) {
      if (reply.length !== 0 || toolcalls.length !== 0) {
        request.resolve({
          index: 0,
          finish_reason: toolcalls.length === 0 ? "stop" : "tool_calls",
          message: {
            role: "assistant",
            content: reply,
            reasoning_content: "进行了一些喵喵思考...大概？",
            tool_calls: toolcalls,
          },
        });
      } else {
        // 没有提供回复或工具调用就退出了
        const rejectReason = prompt("拒绝回复的原因(可选): ") ?? undefined;
        request.reject(rejectReason);
      }
      console.log(">----回复生成成功喵---->");
      break;
    }
  }
}
