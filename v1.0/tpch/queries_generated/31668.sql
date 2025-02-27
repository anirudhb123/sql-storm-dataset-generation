WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey = sh.s_nationkey)
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn,
           SUM(o.o_totalprice) OVER (PARTITION BY o.o_orderstatus) AS status_total
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
),
CriticalOrders AS (
    SELECT os.o_orderkey, os.o_totalprice,
           (CASE 
                WHEN os.o_totalprice > 1000 THEN 'High Value'
                WHEN os.o_totalprice BETWEEN 500 AND 1000 THEN 'Medium Value'
                ELSE 'Low Value'
            END) AS value_category
    FROM OrderStats os
    WHERE os.rn <= 10
)
SELECT DISTINCT 
    p.p_name, 
    p.p_retailprice, 
    COALESCE(r.r_name, 'Unknown') AS region, 
    sh.level AS supplier_level, 
    co.value_category,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN CriticalOrders co ON l.l_orderkey = co.o_orderkey
JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY p.p_name, p.p_retailprice, r.r_name, sh.level, co.value_category
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
ORDER BY total_sales DESC;
