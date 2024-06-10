import axios from "axios";
import { API_PATHS } from "./api.paths";
import { Battle } from "../types/Battle.type";

export const getBattles = async () => {
  const url = `${API_PATHS.baseURL}${API_PATHS.battles}`;

  try {
    const response = await axios.get(url);
    return response;
  } catch (error) {
    console.error("Error fething battles:", error);
    throw error;
  }
};
