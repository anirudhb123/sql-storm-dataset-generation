WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal + r.random_value AS s_acctbal, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM SupplierCTE scte
    JOIN supplier s ON scte.s_suppkey = s.s_suppkey
    CROSS JOIN (SELECT RANDOM() * 500 AS random_value) r
    WHERE scte.s_acctbal + r.random_value < 5000
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS unique_customers,
        MAX(l.l_shipdate) AS latest_shipdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY o.o_orderkey
),
PartSupplier AS (
    SELECT p.p_partkey, 
           p.p_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
FilteredParts AS (
    SELECT p.*, 
           CASE 
               WHEN total_supplycost IS NULL THEN 0
               ELSE total_supplycost 
           END AS adjusted_supplycost
    FROM PartSupplier p
)

SELECT 
    r.r_name AS region_name,
    NS.n_name AS nation_name,
    c.c_name AS customer_name,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    SUM(os.total_sales) AS total_revenue,
    AVG(f.avg_price) AS average_part_price,
    MAX(sct.s_acctbal) AS max_supplier_balance
FROM region r
INNER JOIN nation NS ON r.r_regionkey = NS.n_regionkey
INNER JOIN customer c ON c.c_nationkey = NS.n_nationkey
LEFT JOIN OrderSummary os ON c.c_custkey = os.o_orderkey
LEFT JOIN FilteredParts f ON os.o_orderkey = f.p_partkey
LEFT JOIN SupplierCTE sct ON f.p_partkey = sct.ps_partkey
WHERE c.c_acctbal IS NOT NULL
GROUP BY r.r_name, NS.n_name, c.c_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_revenue DESC
LIMIT 10;
