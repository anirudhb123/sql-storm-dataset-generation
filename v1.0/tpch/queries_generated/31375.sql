WITH RECURSIVE SupplierCTE AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, c.level + 1
    FROM supplier s
    INNER JOIN SupplierCTE c ON s.s_acctbal > c.s_acctbal
    WHERE c.level < 10
),
RegionalOrders AS (
    SELECT n.n_nationkey, r.r_regionkey, COUNT(o.o_orderkey) AS order_count
    FROM orders o 
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_nationkey, r.r_regionkey
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT r.r_name, ro.order_count, s.s_name, 
       CASE 
           WHEN ro.order_count IS NULL THEN 'No orders'
           ELSE CAST(ro.order_count AS VARCHAR)
       END AS order_status,
       p.p_name, p.total_cost
FROM Region r
LEFT JOIN RegionalOrders ro ON r.r_regionkey = ro.r_regionkey
LEFT JOIN SupplierCTE s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps
                                             JOIN RankedParts rp ON ps.ps_partkey = rp.p_partkey
                                             WHERE rp.rnk = 1)
LEFT JOIN RankedParts p ON p.rnk = 1
ORDER BY r.r_name, total_cost DESC;
