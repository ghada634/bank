-- Séquences

CREATE SEQUENCE c_id_sequence
  MINVALUE 10001
  MAXVALUE 99999999
  START WITH 10001
  INCREMENT BY 1
  CACHE 20;

CREATE SEQUENCE a_id_sequence
  MINVALUE 100011
  MAXVALUE 9999999
  START WITH 100011
  INCREMENT BY 1
  CACHE 20;

CREATE SEQUENCE b_id_sequence
  MINVALUE 101
  MAXVALUE 9999999999
  START WITH 101
  INCREMENT BY 1
  CACHE 20;

CREATE SEQUENCE t_id_sequence
  MINVALUE 1001
  MAXVALUE 9999999999
  START WITH 1001
  INCREMENT BY 1
  CACHE 20;

-- Tables

CREATE TABLE EMP_LOGIN
(
	username varchar(100),
	user_password varchar(100)
);

CREATE TABLE customer 
(
	customer_id integer NOT NULL PRIMARY KEY,
	name VARCHAR(50) NOT NULL,
	phone VARCHAR(50) NOT NULL,
	email VARCHAR(50) NOT NULL,
	house_no VARCHAR(50) NOT NULL,
	city VARCHAR(50) NOT NULL,
	zipcode VARCHAR(50) NOT NULL,
	username varchar(50) UNIQUE NOT NULL,
	password varchar(50) NOT NULL
);

CREATE TABLE ACCOUNTS
(	
	account_id integer NOT NULL PRIMARY KEY,
	customer_id integer NOT NULL,
	date_opened DATE NOT NULL,
	current_balance FLOAT,
	FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE BRANCH
( 
	branch_id INTEGER NOT NULL PRIMARY KEY,
	name varchar(50) NOT NULL,
	house_no VARCHAR(50) NOT NULL,
	city VARCHAR(50) NOT NULL,
	zip_code VARCHAR(50) NOT NULL
);

CREATE TABLE TRANSACTION 
(
	transaction_id integer NOT NULL PRIMARY KEY,
	account_id integer NOT NULL,
	branch_id integer NOT NULL,
	date_of_transaction DATE NOT NULL,
	amount FLOAT NOT NULL,
	action VARCHAR(20), 
	FOREIGN KEY (account_id) REFERENCES ACCOUNTS(account_id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (branch_id) REFERENCES BRANCH(branch_id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Insertions corrigées (avec username & password)

INSERT INTO CUSTOMER 
(customer_id,name,phone,email,house_no,city,zipcode, username, password)
VALUES
(NEXTVAL('c_id_sequence'),'Mahade','01671648062','undefinedmahade@gmail.com','Q5','Dhaka','1207', 'mahade123', 'password123');

INSERT INTO CUSTOMER 
(customer_id,name,phone,email,house_no,city,zipcode, username, password)
VALUES
(NEXTVAL('c_id_sequence'),'Riad','0173832700','riad566@gmail.com','370/371','Dhaka','1217', 'riad56', 'pass456');

INSERT INTO ACCOUNTS 
(account_id, customer_id, date_opened,current_balance)
VALUES
(NEXTVAL('a_id_sequence'), 10001,'2016-02-18',50000);

INSERT INTO ACCOUNTS 
(account_id, customer_id, date_opened,current_balance)
VALUES
(NEXTVAL('a_id_sequence'), 10002,'2016-02-20',95000);

INSERT INTO BRANCH VALUES (NEXTVAL('b_id_sequence'),'Malibagh','M502', 'Dhaka', '1217');
INSERT INTO BRANCH VALUES (NEXTVAL('b_id_sequence'),'Mohammadpur','M555', 'Dhaka', '1207');

INSERT INTO TRANSACTION VALUES (NEXTVAL('t_id_sequence'),100011,101,CURRENT_DATE,5000,'withdraw');

-- Procédures

CREATE OR REPLACE PROCEDURE insert_into_emp_login(un varchar, up varchar)
LANGUAGE plpgsql AS
$$
BEGIN
	INSERT INTO EMP_LOGIN(username,user_password) VALUES (un,up);
END;
$$;

CREATE OR REPLACE PROCEDURE insert_into_customer(nm varchar, ph varchar, em varchar, hn varchar, city varchar, zp varchar, un varchar, pwd varchar) 
LANGUAGE plpgsql AS
$$
BEGIN
	INSERT INTO CUSTOMER 
	(customer_id,name,phone,email,house_no,city,zipcode,username,password)
	VALUES
	(NEXTVAL('c_id_sequence'), nm, ph, em, hn, city, zp, un, pwd);
END;
$$;

CREATE OR REPLACE PROCEDURE insert_into_accounts(cid varchar, cur_bal varchar)
LANGUAGE plpgsql AS
$$
BEGIN
	INSERT INTO ACCOUNTS 
	(account_id, customer_id, date_opened, current_balance)
	VALUES
	(NEXTVAL('a_id_sequence'), CAST(cid AS integer), CURRENT_DATE, CAST(cur_bal AS float));
END;
$$;

CREATE OR REPLACE PROCEDURE insert_into_branch(nm varchar, hn varchar, cy varchar, zc varchar)
LANGUAGE plpgsql AS
$$
BEGIN
	INSERT INTO BRANCH VALUES (NEXTVAL('b_id_sequence'), nm, hn, cy, zc);
END;
$$;

CREATE OR REPLACE PROCEDURE insert_into_transaction(aid varchar, bid varchar, amt varchar, acn varchar)
LANGUAGE plpgsql AS
$$
BEGIN
	INSERT INTO TRANSACTION VALUES (NEXTVAL('t_id_sequence'), CAST(aid AS integer), CAST(bid AS integer), CURRENT_DATE, CAST(amt AS float), acn);
	UPDATE ACCOUNTS
	SET current_balance = current_balance + CASE WHEN acn = 'Deposit' THEN CAST(amt AS float) ELSE -CAST(amt AS float) END
	WHERE account_id = CAST(aid AS integer);
END;
$$;

-- Fonctions

CREATE OR REPLACE FUNCTION get_current_amount(a_id integer) RETURNS float AS
$$
DECLARE
	current_amount float;
BEGIN
	SELECT current_balance INTO current_amount FROM accounts WHERE account_id = a_id;
	RETURN current_amount;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_transaction(a_id integer) RETURNS refcursor AS
$$
DECLARE
	my_cursor refcursor;
BEGIN
	OPEN my_cursor FOR
	SELECT transaction_id, branch_id, date_of_transaction, amount, action
	FROM transaction
	WHERE account_id = a_id
	ORDER BY date_of_transaction DESC;
	RETURN my_cursor;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION e_login(f_name varchar, f_password varchar) RETURNS refcursor AS
$$
DECLARE
	my_cursor refcursor;
BEGIN
	OPEN my_cursor FOR
	SELECT username, user_password FROM emp_login
	WHERE username = f_name AND user_password = f_password;
	RETURN my_cursor;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION customer_info(a_id integer) RETURNS refcursor AS
$$
DECLARE
	my_cursor refcursor;
BEGIN
	OPEN my_cursor FOR
	SELECT c.name, c.phone
	FROM accounts ac
	JOIN customer c ON ac.customer_id = c.customer_id
	WHERE ac.account_id = a_id;
	RETURN my_cursor;
END;
$$ LANGUAGE plpgsql;

-- Triggers

CREATE OR REPLACE FUNCTION deposit_balance_func() RETURNS trigger AS
$$
BEGIN
	IF NEW.action = 'Deposit' THEN
		UPDATE accounts
		SET current_balance = current_balance + NEW.amount
		WHERE account_id = NEW.account_id;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER deposit_balance
AFTER INSERT ON transaction
FOR EACH ROW
EXECUTE FUNCTION deposit_balance_func();

CREATE OR REPLACE FUNCTION withdraw_balance_func() RETURNS trigger AS
$$
BEGIN
	IF NEW.action = 'Withdraw' THEN
		UPDATE accounts
		SET current_balance = current_balance - NEW.amount
		WHERE account_id = NEW.account_id;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER withdraw_balance
AFTER INSERT ON transaction
FOR EACH ROW
EXECUTE FUNCTION withdraw_balance_func();
