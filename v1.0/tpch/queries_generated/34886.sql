WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    AND s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
PartAvailability AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT
    p.p_partkey,
    p.p_name,
    COALESCE(pa.total_avail_qty, 0) AS available_quantity,
    c.c_name AS customer_name,
    cos.total_spent,
    ROW_NUMBER() OVER(PARTITION BY p.p_partkey ORDER BY cos.total_spent DESC) AS rank,
    (CASE
        WHEN cos.order_count > 3 THEN 'Frequent'
        WHEN cos.order_count IS NULL THEN 'No Orders'
        ELSE 'Occasional'
     END) AS customer_category
FROM part p
LEFT JOIN PartAvailability pa ON p.p_partkey = pa.ps_partkey
LEFT JOIN CustomerOrderSummary cos ON cos.cust_key IN (
    SELECT DISTINCT o.o_custkey
    FROM orders o
    INNER JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_quantity > (SELECT AVG(l_quantity) FROM lineitem)
)
WHERE p.p_retailprice > 100
ORDER BY available_quantity DESC, total_spent DESC;
