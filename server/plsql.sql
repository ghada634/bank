-- 🔁 Supprimer les anciennes versions si elles existent

DROP PROCEDURE IF EXISTS insert_into_emp_login(VARCHAR, VARCHAR);
DROP PROCEDURE IF EXISTS insert_into_customer(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR);
DROP PROCEDURE IF EXISTS insert_into_accounts(VARCHAR, VARCHAR);
DROP PROCEDURE IF EXISTS insert_into_branch(VARCHAR, VARCHAR, VARCHAR, VARCHAR);
DROP PROCEDURE IF EXISTS insert_into_transaction(VARCHAR, VARCHAR, VARCHAR, VARCHAR);

DROP FUNCTION IF EXISTS get_current_amount(INTEGER);
DROP FUNCTION IF EXISTS get_transaction(INTEGER);
DROP FUNCTION IF EXISTS e_login(VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS customer_info(INTEGER);

DROP TRIGGER IF EXISTS deposit_balance ON transaction;
DROP TRIGGER IF EXISTS withdraw_balance ON transaction;
DROP FUNCTION IF EXISTS deposit_balance_func();
DROP FUNCTION IF EXISTS withdraw_balance_func();

-- 🏦 PROCÉDURES

CREATE OR REPLACE PROCEDURE insert_into_emp_login(un VARCHAR, up VARCHAR)
LANGUAGE SQL AS $$
  INSERT INTO emp_login(username, user_password) VALUES (un, up);
$$;

CREATE OR REPLACE PROCEDURE insert_into_customer(
  nm VARCHAR, ph VARCHAR, em VARCHAR, hn VARCHAR,
  cy VARCHAR, zp VARCHAR, un VARCHAR, pwd VARCHAR
)
LANGUAGE SQL AS $$
  INSERT INTO customer(customer_id, name, phone, email, house_no, city, zipcode, username, password)
  VALUES (NEXTVAL('c_id_sequence'), nm, ph, em, hn, cy, zp, un, pwd);
$$;

CREATE OR REPLACE PROCEDURE insert_into_accounts(cid VARCHAR, cur_bal VARCHAR)
LANGUAGE SQL AS $$
  INSERT INTO accounts(account_id, customer_id, date_opened, current_balance)
  VALUES (NEXTVAL('a_id_sequence'), CAST(cid AS INTEGER), CURRENT_DATE, CAST(cur_bal AS REAL));
$$;

CREATE OR REPLACE PROCEDURE insert_into_branch(nm VARCHAR, hn VARCHAR, cy VARCHAR, zc VARCHAR)
LANGUAGE SQL AS $$
  INSERT INTO branch(branch_id, name, house_no, city, zip_code)
  VALUES (NEXTVAL('b_id_sequence'), nm, hn, cy, zc);
$$;

CREATE OR REPLACE PROCEDURE insert_into_transaction(aid VARCHAR, bid VARCHAR, amt VARCHAR, acn VARCHAR)
LANGUAGE SQL AS $$
  INSERT INTO transaction(transaction_id, account_id, branch_id, date_of_transaction, amount, action)
  VALUES (
    NEXTVAL('t_id_sequence'),
    CAST(aid AS INTEGER),
    CAST(bid AS INTEGER),
    CURRENT_DATE,
    CAST(amt AS REAL),
    acn
  );
  UPDATE accounts
    SET current_balance = current_balance + CASE WHEN acn = 'Deposit' THEN CAST(amt AS REAL)
                                                WHEN acn = 'Withdraw' THEN -CAST(amt AS REAL)
                                                ELSE 0 END
  WHERE account_id = CAST(aid AS INTEGER);
$$;

-- 📊 FONCTIONS

CREATE OR REPLACE FUNCTION get_current_amount(a_id INTEGER) RETURNS NUMERIC AS $$
DECLARE
  current_amount NUMERIC;
BEGIN
  SELECT current_balance INTO current_amount FROM accounts WHERE account_id = a_id;
  RETURN current_amount;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_transaction(a_id INTEGER) RETURNS TABLE(
  transaction_id INTEGER,
  branch_id INTEGER,
  date_of_transaction DATE,
  amount REAL,
  action VARCHAR
) AS $$
BEGIN
  RETURN QUERY
    SELECT transaction_id, branch_id, date_of_transaction, amount, action
    FROM transaction
    WHERE account_id = a_id
    ORDER BY date_of_transaction DESC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION e_login(f_name VARCHAR, f_password VARCHAR) RETURNS TABLE(username VARCHAR, user_password VARCHAR) AS $$
BEGIN
  RETURN QUERY
    SELECT username, user_password
    FROM emp_login
    WHERE username = f_name AND user_password = f_password;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION customer_info(a_id INTEGER) RETURNS TABLE(name VARCHAR, phone VARCHAR) AS $$
BEGIN
  RETURN QUERY
    SELECT c.name, c.phone
    FROM accounts ac
    JOIN customer c USING (customer_id)
    WHERE ac.account_id = a_id;
END;
$$ LANGUAGE plpgsql;

-- 🔔 TRIGGERS

CREATE OR REPLACE FUNCTION deposit_balance_func() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.action = 'Deposit' THEN
    UPDATE accounts
      SET current_balance = current_balance + NEW.amount
      WHERE account_id = NEW.account_id;
  ELSIF NEW.action = 'Withdraw' THEN
    UPDATE accounts
      SET current_balance = current_balance - NEW.amount
      WHERE account_id = NEW.account_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER deposit_balance
  AFTER INSERT ON transaction
  FOR EACH ROW
  EXECUTE FUNCTION deposit_balance_func();
