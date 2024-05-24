import { AppService } from './app.service';
import { User } from './types/User.type';
export declare class AppController {
    private readonly appService;
    constructor(appService: AppService);
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
    createUser(user: User): Promise<{
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
