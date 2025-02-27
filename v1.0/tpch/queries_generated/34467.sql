WITH RECURSIVE SalesCTE AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        1 AS level
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY c.c_custkey, c.c_name

    UNION ALL

    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        level + 1
    FROM SalesCTE s
    JOIN orders o ON s.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY c.c_custkey, c.c_name
),

SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)

SELECT 
    r.r_name, 
    n.n_name,
    COALESCE(SUM(s.total_sales), 0) AS customer_sales,
    COALESCE(SUM(ss.total_supply_cost), 0) AS supplier_costs,
    AVG(ss.total_supply_cost) OVER (PARTITION BY r.r_regionkey) AS avg_supply_cost_by_region,
    COUNT(DISTINCT c.c_custkey) AS distinct_customers,
    CASE 
        WHEN COALESCE(SUM(s.total_sales), 0) > 100000 THEN 'High' 
        WHEN COALESCE(SUM(s.total_sales), 0) BETWEEN 50000 AND 100000 THEN 'Medium' 
        ELSE 'Low' 
    END AS sales_category
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SalesCTE s ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = s.c_custkey)
LEFT JOIN SupplierSales ss ON s.c_custkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ss.s_suppkey)
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 1, 2;
