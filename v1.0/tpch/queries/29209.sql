
WITH SupplierInfo AS (
    SELECT s_name, s_address, s_nationkey, 
           LENGTH(s_comment) AS comment_length,
           SUBSTRING(s_comment FROM 1 FOR 20) AS short_comment
    FROM supplier
),
PartDetails AS (
    SELECT p_name, p_brand, p_mfgr,
           CONCAT(p_name, ' ', p_brand) AS full_description
    FROM part
),
OrderCounts AS (
    SELECT o_custkey, COUNT(o_orderkey) AS order_count
    FROM orders
    GROUP BY o_custkey
),
CustomerInfo AS (
    SELECT c_name, c_address, c_nationkey, c_mktsegment, 
           REPLACE(c_comment, 'customer', 'Client') AS modified_comment
    FROM customer
)
SELECT ci.c_name AS customer_name,
       ci.modified_comment,
       si.s_name AS supplier_name,
       si.short_comment,
       pd.full_description,
       oc.order_count
FROM CustomerInfo ci
JOIN OrderCounts oc ON ci.c_nationkey = oc.o_custkey
JOIN SupplierInfo si ON ci.c_nationkey = si.s_nationkey
JOIN PartDetails pd ON pd.p_mfgr = si.s_name
WHERE si.comment_length > 50
ORDER BY ci.c_name, pd.p_name;
