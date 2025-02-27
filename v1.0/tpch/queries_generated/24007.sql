WITH RecursivePart AS (
    SELECT p_partkey, p_size, p_retailprice, p_name, 1 AS level
    FROM part
    WHERE p_size < 10
    UNION ALL
    SELECT p.p_partkey, p.p_size, p.p_retailprice, p.p_name, rp.level + 1
    FROM part p
             JOIN RecursivePart rp ON p.p_size > rp.p_size
    WHERE rp.level < 5
),
TotalSales AS (
    SELECT l.l_partkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
             JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY l.l_partkey
),
SupplierDetails AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
             JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
)
SELECT p.p_partkey,
       p.p_name,
       COALESCE(ts.total_revenue, 0) AS total_revenue,
       CASE
           WHEN ts.total_revenue IS NULL THEN 'No Sales'
           ELSE 'Sales Exist'
       END AS sales_status,
       CASE
           WHEN sd.total_supply_cost IS NOT NULL THEN sd.s_acctbal / NULLIF(sd.total_supply_cost, 0)
           ELSE NULL
       END AS balance_per_supply_cost,
       COUNT(DISTINCT sd.s_suppkey) OVER (PARTITION BY p.p_partkey) AS supplier_count
FROM part p
         LEFT JOIN TotalSales ts ON p.p_partkey = ts.l_partkey
         LEFT JOIN SupplierDetails sd ON p.p_partkey = sd.s_suppkey
WHERE (p.p_retailprice > 10.00 OR p.p_name LIKE 'A%')
  AND (p.p_comment IS NULL OR p.p_comment != '')
  AND EXISTS (SELECT 1
              FROM nation n
              WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT MAX(o2.o_orderkey) FROM orders o2 WHERE o2.o_orderstatus = 'F')))
              )
ORDER BY p.p_partkey, sales_status DESC;
