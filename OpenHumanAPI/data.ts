export interface ChatRequest {
  // API请求的数据
  messages: Message[];
  model: string;

  // 一些可能无关紧要的东西（也就是写了也不一定遵守的）
  stream?: boolean;
  stop?: string | string[];
  tools?: {
    type: "function";
    function: {
      name: string;
      description: string;
      parameters?: object;
    };
  }[];
}
export interface Message {
  role: string;
  content: string;
  name?: string;
  tool_call_id?: string;
}

export interface Completion {
  id: string;
  object: "chat.completion";
  created: number;
  model: string;
  system_fingerprint: string;
  choices: Choice[];
  usage: {
    completion_tokens: number;
    prompt_tokens: number;
    total_tokens: number;
  };
}
export interface Choice {
  finish_reason:
    | "stop"
    | "tool_calls"
    | "insufficient_system_resource"
    | "content_filter"
    | "length";
  index: number;
  message: {
    content?: string;
    reasoning_content?: string;
    tool_calls?: ToolCall[];
    role: "assistant";
  };
}
export interface ToolCall {
  id: string;
  type: "function";
  function: { arguments: string; name: string };
}

export function messageToString(message: Message): string {
  switch (message.role) {
    case "system":
    case "user":
    case "assistant":
      if (message.name) {
        return `${message.name}(${message.role}): ${message.content}`;
      } else {
        return `${message.role}: ${message.content}`;
      }
    case "tool":
      return `ToolCall(id:${message.tool_call_id}): ${message.content}`;
    default:
      return "Unknown type of message: " + JSON.stringify(message);
  }
}
