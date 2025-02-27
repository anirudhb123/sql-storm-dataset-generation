WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation, s.s_address, s.s_phone, s.s_acctbal,
           SUBSTRING(s.s_comment, 1, 20) AS short_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type,
           CONCAT(p.p_brand, ' ', p.p_name) AS full_description, p.p_retailprice
    FROM part p
),
CustomerPurchaseSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS orders_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT sd.s_name AS supplier_name, sd.nation AS supplier_nation, pd.full_description, 
       pd.p_retailprice, cps.c_name AS customer_name, cps.total_spent, cps.orders_count,
       LENGTH(sd.short_comment) AS comment_length
FROM SupplierDetails sd
JOIN partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN CustomerPurchaseSummary cps ON cps.total_spent > pd.p_retailprice
WHERE LENGTH(sd.short_comment) > 10
ORDER BY sd.nation, cps.total_spent DESC, pd.p_retailprice;
