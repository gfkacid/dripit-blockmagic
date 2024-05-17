USE dripit;

CREATE TABLE dbo.users (
	id INT IDENTITY (1, 1) PRIMARY KEY,
	email VARCHAR (50) NOT NULL,
	login_type INT NOT NULL,
	username VARCHAR (50) NOT NULL,
	avatar VARCHAR (1000),
	wallet CHAR (42) NOT NULL,
	referred_by INT,
	auth_identifier VARCHAR (100) NOT NULL
);

CREATE TABLE dbo.artists (
	id INT IDENTITY (1, 1) PRIMARY KEY,
	spotify_id VARCHAR (50) NOT NULL,
	name VARCHAR (50) NOT NULL,
	slug VARCHAR (50) NOT NULL,
	image VARCHAR (1000) NOT NULL,
	bio TEXT
);

CREATE TABLE dbo.battles (
    id INT IDENTITY (1, 1) PRIMARY KEY,
    type TINYINT NOT NULL,
    status TINYINT NOT NULL,
    sideA_id INT NOT NULL,
    FOREIGN KEY (sideA_id)
        REFERENCES dbo.artists(id),
    sideB_id INT NOT NULL,
    FOREIGN KEY (sideB_id)
        REFERENCES dbo.artists(id),
    amountA BIGINT NOT NULL,
    amountB BIGINT NOT NULL,
    total BIGINT NOT NULL,
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    created_by INT NOT NULL,
    FOREIGN KEY (created_by)
        REFERENCES dbo.users(id)
);

CREATE TABLE dbo.positions (
	id INT IDENTITY (1, 1) PRIMARY KEY,
	battle_id INT NOT NULL,
	FOREIGN KEY (battle_id)
		REFERENCES dbo.battles(id)
		ON DELETE NO ACTION ON UPDATE CASCADE,
	user_id INT NOT NULL,
	FOREIGN KEY (user_id)
		REFERENCES dbo.users(id)
		ON DELETE NO ACTION ON UPDATE CASCADE,
	side BIT NOT NULL,
	amount BIGINT NOT NULL,
	created_at DATETIME NOT NULL,
	won BIT NOT NULL,
	updated_at DATETIME,
);

CREATE TABLE dbo.claims (
	id INT IDENTITY (1, 1) PRIMARY KEY,
	position_id INT NOT NULL,
	FOREIGN KEY (position_id)
		REFERENCES dbo.positions(id),
	amount BIGINT,
	claimed_at DATETIME,
	user_id INT NOT NULL,
	FOREIGN KEY (user_id)
		REFERENCES dbo.users(id)
);

CREATE TABLE dbo.artist_spotify_stats (
	id INT IDENTITY (1, 1) PRIMARY KEY,
	artist_id INT NOT NULL,
	FOREIGN KEY (artist_id)
		REFERENCES dbo.artists(id),
	total_plays INT NOT NULL,
	followers INT NOT NULL,
	updated_at DATETIME
);

CREATE TABLE dbo.spodity_weekly_pllays (
	id INT IDENTITY (1, 1) PRIMARY KEY,
	artist_id INT NOT NULL,
	FOREIGN KEY (artist_id)
		REFERENCES dbo.artists(id),
	total_plays INT NOT NULL,
	start_date DATETIME NOT NULL,
	end_date DATETIME NOT NULL,
);