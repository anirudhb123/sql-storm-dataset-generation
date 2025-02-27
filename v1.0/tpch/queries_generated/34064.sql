WITH RECURSIVE SuppliersCTE AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal) 
        FROM supplier 
        WHERE s_acctbal IS NOT NULL
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, level + 1
    FROM supplier s
    JOIN SuppliersCTE cte ON s.s_suppkey = cte.s_suppkey
    WHERE s.s_acctbal > cte.s_acctbal
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, 
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    n.n_name AS nation,
    r.r_name AS region,
    SUM(os.total_sales) AS total_sales,
    COUNT(DISTINCT ps.p_partkey) AS unique_parts_supplied,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM OrderSummary os
JOIN customer c ON os.o_orderkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN PartSupplier ps ON os.o_orderkey = ps.p_partkey
WHERE n.n_name IS NOT NULL AND r.r_name IS NOT NULL
GROUP BY n.n_name, r.r_name
HAVING SUM(os.total_sales) > (
    SELECT total_sales
    FROM (
        SELECT SUM(total_sales) AS total_sales
        FROM OrderSummary
        GROUP BY o_orderkey
    ) AS sales_avg
    WHERE total_sales IS NOT NULL
    ORDER BY sales_avg.total_sales DESC
    LIMIT 1
)
ORDER BY total_sales DESC;
