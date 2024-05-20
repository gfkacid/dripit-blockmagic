import { User } from './types/User.type';
export declare class AppService {
    getUsers(): Promise<{
        id: number;
        email: string;
        login_type: number;
        username: string;
        avatar: string;
        wallet: string;
        referred_by: number;
        auth_identifier: string;
    }[]>;
    createUser(data: User): Promise<{
        id: number;
        email: string;
        login_type: number;
        username: string;
        avatar: string;
        wallet: string;
        referred_by: number;
        auth_identifier: string;
    }>;
}
