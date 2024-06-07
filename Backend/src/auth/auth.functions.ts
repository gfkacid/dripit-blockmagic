import * as jwt from "jsonwebtoken";
import { SignMessageContent } from "./dto/auth.dto";

export const isRequestAuthorizedForUser = async (req: Request) => {
  const authorizationHeader = req.headers["authorization"];
  if (!authorizationHeader) {
    // Authorization header is missing
    return false;
  }

  const token = authorizationHeader.split(" ")[1];
  if (!token) {
    // Token is missing in the Authorization header
    return false;
  }

  const secret = process.env.JWT_SECRET;
  let isAuthorized: boolean | number = false;
  try {
    const decodedData = jwt.verify(token, secret) as SignMessageContent;
    isAuthorized = decodedData.id;
  } catch (err) {
    // Token exist but validation failed / invalid /
    isAuthorized = false;
  }

  return isAuthorized;
};
