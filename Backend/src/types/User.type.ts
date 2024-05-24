export class User {
  id?: number;
  email: string;
  login_type: number;
  username: string;
  avatar?: string;
  wallet: string;
  referred_by?: number;
  auth_identifier: string;
}
