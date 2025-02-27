
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    UNION ALL
    SELECT 
        o.o_orderkey,
        s.total_sales + SUM(l.l_extendedprice * (1 - l.l_discount)),
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        Sales_CTE s ON o.o_orderkey = s.o_orderkey
    WHERE 
        o.o_orderdate < s.o_orderdate
    GROUP BY 
        o.o_orderkey, o.o_orderdate, s.total_sales
),
Ranked_Sales AS (
    SELECT 
        s.o_orderkey,
        s.total_sales,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        Sales_CTE s
)
SELECT 
    p.p_name,
    r.r_name,
    n.n_name,
    COUNT(o.o_orderkey) AS order_count,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    AVG(l.l_quantity) AS avg_quantity,
    CASE 
        WHEN SUM(l.l_discount) IS NULL THEN 'No Discount'
        ELSE 'Discount Applied'
    END AS discount_status
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size > 20 AND
    (l.l_returnflag = 'N' OR l.l_linestatus = 'O')
GROUP BY 
    p.p_name, r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY 
    total_supply_cost DESC, p.p_name
FETCH FIRST 10 ROWS ONLY;
