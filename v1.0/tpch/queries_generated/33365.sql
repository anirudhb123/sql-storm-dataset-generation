WITH RecursiveSupplierHierarchy AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_nationkey,
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal)
        FROM supplier s2
    )
    UNION ALL
    SELECT s.s_suppkey,
           s.s_name,
           s.s_nationkey,
           level + 1
    FROM supplier s
    INNER JOIN RecursiveSupplierHierarchy rsh ON s.s_nationkey = rsh.s_nationkey
    WHERE rsh.level < 5
),
RecentOrders AS (
    SELECT o.o_orderkey,
           o.o_custkey,
           o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(month, -6, GETDATE())
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
TopCustomers AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(ro.total_revenue) AS total_spent
    FROM customer c
    JOIN RecentOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(ro.total_revenue) > 10000
)
SELECT p.p_name,
       p.p_brand,
       p.p_type,
       COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
       SUM(ps.ps_availqty) AS total_available_quantity,
       SUM(ps.ps_supplycost) AS total_supply_cost,
       ROW_NUMBER() OVER(PARTITION BY p.p_size ORDER BY SUM(ps.ps_availqty) DESC) AS rank,
       CASE 
           WHEN AVG(s.s_acctbal) IS NULL THEN 'No Suppliers' 
           ELSE 'Average Balance: ' || AVG(s.s_acctbal)::varchar 
       END AS average_supplier_account_balance
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2
     )
GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type
HAVING COUNT(DISTINCT ps.ps_suppkey) > 2 AND 
       SUM(ps.ps_availqty) > (
           SELECT AVG(ps2.ps_availqty) 
           FROM partsupp ps2 
           WHERE ps2.ps_partkey = p.p_partkey
       )
ORDER BY total_supply_cost DESC
FETCH FIRST 10 ROWS ONLY;
