USE dripit;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR (50) NOT NULL,
    login_type INT NOT NULL,
    username VARCHAR (50) NOT NULL,
    avatar VARCHAR (1000),
    wallet CHAR (42) NOT NULL,
    referred_by INT,
    auth_identifier VARCHAR (100) NOT NULL
);

CREATE TABLE artists (
    id INT AUTO_INCREMENT PRIMARY KEY,
    spotify_id VARCHAR (50) NOT NULL,
    name VARCHAR (50) NOT NULL,
    slug VARCHAR (50) NOT NULL,
    image VARCHAR (1000) NOT NULL,
    bio TEXT
);

CREATE TABLE battles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    type TINYINT NOT NULL,
    status TINYINT NOT NULL,
    sideA_id INT NOT NULL,
    FOREIGN KEY (sideA_id)
        REFERENCES artists(id),
    sideB_id INT NOT NULL,
    FOREIGN KEY (sideB_id)
        REFERENCES artists(id),
    amountA BIGINT NOT NULL,
    amountB BIGINT NOT NULL,
    total BIGINT NOT NULL,
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    created_by INT NOT NULL,
    FOREIGN KEY (created_by)
        REFERENCES users(id)
);

CREATE TABLE positions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    battle_id INT NOT NULL,
    FOREIGN KEY (battle_id)
        REFERENCES battles(id)
        ON DELETE NO ACTION ON UPDATE CASCADE,
    user_id INT NOT NULL,
    FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE NO ACTION ON UPDATE CASCADE,
    side BIT NOT NULL,
    amount BIGINT NOT NULL,
    created_at DATETIME NOT NULL,
    won BIT NOT NULL,
    updated_at DATETIME
);

CREATE TABLE claims (
    id INT AUTO_INCREMENT PRIMARY KEY,
    position_id INT NOT NULL,
    FOREIGN KEY (position_id)
        REFERENCES positions(id),
    amount BIGINT,
    claimed_at DATETIME,
    user_id INT NOT NULL,
    FOREIGN KEY (user_id)
        REFERENCES users(id)
);

CREATE TABLE artist_spotify_stats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    artist_id INT NOT NULL,
    FOREIGN KEY (artist_id)
        REFERENCES artists(id),
    total_plays INT NOT NULL,
    followers INT NOT NULL,
    updated_at DATETIME
);

CREATE TABLE spodity_weekly_plays (
    id INT AUTO_INCREMENT PRIMARY KEY,
    artist_id INT NOT NULL,
    FOREIGN KEY (artist_id)
        REFERENCES artists(id),
    total_plays INT NOT NULL,
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL
);

