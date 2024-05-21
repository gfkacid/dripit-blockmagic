import axios from "axios";
import { API_PATHS } from "./api.paths";
import { User } from "../types/User.type";

export const createNewUser = async (user: User) => {
  const url = `${API_PATHS.baseURL}${API_PATHS.createUser}`;

  try {
    const response = await axios.post(url, user);
    return response;
  } catch (error) {
    console.error("Error creating new user:", error);
    throw error;
  }
};
