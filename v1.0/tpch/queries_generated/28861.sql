WITH SupplierDetails AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_address,
           s.s_phone,
           s.s_acctbal,
           CONCAT(s.s_name, ' ', s.s_address) AS full_address,
           LENGTH(s.s_comment) AS comment_length
    FROM supplier s
), 
CustomerDetails AS (
    SELECT c.c_custkey,
           c.c_name,
           CONCAT(c.c_name, ' (', c.c_phone, ')') AS contact_info,
           LENGTH(c.c_comment) AS customer_comment_length
    FROM customer c
), 
PartDetails AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_brand,
           p.p_retailprice,
           REGEXP_REPLACE(p.p_comment, '[^a-zA-Z0-9 ]', '') AS sanitized_comment
    FROM part p
), 
OrderDetails AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           YEAR(o.o_orderdate) AS order_year,
           COUNT(l.l_orderkey) AS total_line_items
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
), 
EnhancedDetails AS (
    SELECT sd.s_suppkey,
           sd.s_name,
           cd.c_custkey,
           cd.c_name,
           pd.p_partkey,
           pd.p_name,
           od.o_orderkey,
           od.o_orderdate,
           sd.comment_length AS supplier_comment_length,
           cd.customer_comment_length AS customer_comment_length,
           od.total_line_items,
           ROUND(sd.s_acctbal, 2) AS supplier_balance,
           ROUND(pd.p_retailprice * 0.90, 2) AS discounted_price
    FROM SupplierDetails sd
    JOIN CustomerDetails cd ON sd.s_suppkey % 10 = cd.c_custkey % 10
    JOIN PartDetails pd ON pd.p_partkey % 5 = cd.c_custkey % 5
    JOIN OrderDetails od ON od.total_line_items > 5
)
SELECT e.s_name,
       e.c_name,
       e.p_name,
       e.order_year,
       e.discounted_price,
       MAX(e.total_line_items) OVER (PARTITION BY e.order_year) AS max_line_items_per_year,
       COUNT(*) OVER (PARTITION BY e.c_name) AS customer_order_count
FROM EnhancedDetails e
WHERE e.supplier_balance > 100.00
ORDER BY e.order_year DESC, e.c_name ASC;
