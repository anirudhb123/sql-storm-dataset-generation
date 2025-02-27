WITH RECURSIVE TotalSalesCTE AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND 
        o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        c.c_custkey
    UNION ALL
    SELECT 
        c.c_custkey,
        ts.total_sales + SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        TotalSalesCTE ts
    JOIN 
        customer c ON c.c_custkey = ts.c_custkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND 
        o.o_orderdate < DATE '2023-01-01' AND
        ts.total_sales < 100000 -- Arbitrary threshold for recursion
    GROUP BY 
        c.c_custkey, ts.total_sales
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    SUM(ts.total_sales) AS total_sales_amount,
    AVG(ts.total_sales) AS avg_sales_amount
FROM 
    TotalSalesCTE ts
JOIN 
    customer c ON ts.c_custkey = c.c_custkey
JOIN 
    supplier s ON s.s_nationkey = c.c_nationkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey 
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0 AND 
    SUM(ts.total_sales) > 50000
ORDER BY 
    total_sales_amount DESC
LIMIT 10;
