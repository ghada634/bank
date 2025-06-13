-- Supprimer les procédures et fonctions avant création

DROP PROCEDURE IF EXISTS insert_into_emp_login(VARCHAR, VARCHAR);
CREATE OR REPLACE PROCEDURE insert_into_emp_login(un VARCHAR, up VARCHAR)
LANGUAGE SQL AS
$$
INSERT INTO emp_login(username, user_password) VALUES (un, up);
$$;

DROP PROCEDURE IF EXISTS insert_into_customer(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR);
CREATE OR REPLACE PROCEDURE insert_into_customer(
  nm VARCHAR, ph VARCHAR, em VARCHAR, hn VARCHAR, city VARCHAR, zp VARCHAR, un VARCHAR, pwd VARCHAR)
LANGUAGE SQL AS
$$
INSERT INTO customer(customer_id, name, phone, email, house_no, city, zipcode, username, password)
VALUES (NEXTVAL('c_id_sequence'), nm, ph, em, hn, city, zp, un, pwd);
$$;

-- Supprimer et recréer fonction

DROP FUNCTION IF EXISTS get_current_amount(integer);
CREATE OR REPLACE FUNCTION get_current_amount(a_id INTEGER) RETURNS NUMERIC AS $$
DECLARE
  current_amount NUMERIC;
BEGIN
  SELECT current_balance INTO current_amount FROM accounts WHERE account_id = a_id;
  RETURN current_amount;
END;
$$ LANGUAGE plpgsql;

-- Supprimer trigger et fonction associée avant recréation

DROP TRIGGER IF EXISTS deposit_balance ON transaction;
DROP FUNCTION IF EXISTS deposit_balance_func();

CREATE OR REPLACE FUNCTION deposit_balance_func() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.action = 'Deposit' THEN
    UPDATE accounts SET current_balance = current_balance + NEW.amount WHERE account_id = NEW.account_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER deposit_balance
AFTER INSERT ON transaction
FOR EACH ROW EXECUTE FUNCTION deposit_balance_func();
