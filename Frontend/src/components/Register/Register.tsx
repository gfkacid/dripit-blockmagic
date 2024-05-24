"use client";
import { useState } from "react";
import { createNewUser } from "../../lib/api/createUser";
import { hashPassword } from "../../lib/helpers/password.helpers";

import styles from "./Register.module.css";

const Register = () => {
  const [email, setEmail] = useState("");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [avatar, setAvatar] = useState("");
  const [wallet, setWallet] = useState("");
  const [registerStatus, setRegisterStatus] = useState(1);
  const [message, setMessage] = useState("");

  const onRegister = async () => {
    const userData = {
      email,
      login_type: 2,
      username,
      avatar,
      wallet,
      auth_identifier: await hashPassword(password),
    };
    const result = await createNewUser(userData);
    if (result.status === 201) {
      setMessage("Registration Successful");
      setTimeout(() => {
        setMessage("");
      }, 2000);
    } else {
      setRegisterStatus(0);
      setMessage("Registration Failed");
      setTimeout(() => {
        setMessage("");
      }, 2000);
    }
  };

  return (
    <div className={styles.container}>
      <div className={styles.input}>
        <input
          type="email"
          placeholder="Email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
        />
      </div>
      <div className={styles.input}>
        <input
          type="text"
          placeholder="username"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
        />
      </div>
      <div className={styles.input}>
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />
      </div>
      <div className={styles.input}>
        <input
          type="text"
          placeholder="avatar"
          value={avatar}
          onChange={(e) => setAvatar(e.target.value)}
        />
      </div>
      <div className={styles.input}>
        <input
          type="text"
          placeholder="wallet"
          value={wallet}
          onChange={(e) => setWallet(e.target.value)}
        />
      </div>
      <div
        className={
          registerStatus === 1 ? styles.messageSuccess : styles.messageError
        }
      >
        {message}
      </div>
      <button className={styles.button} type="submit" onClick={onRegister}>
        Register
      </button>
    </div>
  );
};

export default Register;
