WITH RECURSIVE Sales_CTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
Ranked_Sales AS (
    SELECT 
        cust.custkey,
        cust.c_name,
        CUME_DIST() OVER (PARTITION BY cust.custkey ORDER BY total_sales DESC) AS sales_rank
    FROM (
        SELECT 
            s_custkey AS custkey,
            SUM(total_sales) AS total_sales
        FROM Sales_CTE
        GROUP BY s_custkey
    ) AS cust
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_suppkey,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    COALESCE(AVG(s.s_acctbal), 0) AS avg_supplier_acctbal
FROM supplier s
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN Ranked_Sales rs ON s.s_suppkey = rs.custkey
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name, n.n_name, s.s_suppkey
ORDER BY total_supply_cost DESC
LIMIT 10;
