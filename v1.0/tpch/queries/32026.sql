
WITH RECURSIVE CTE_Supplier AS (
    SELECT 
        s_suppkey,
        s_name,
        s_acctbal,
        s_nationkey,
        1 AS level
    FROM 
        supplier
    WHERE 
        s_acctbal > 1000
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        cs.level + 1
    FROM 
        supplier s
    JOIN 
        CTE_Supplier cs ON s.s_nationkey = cs.s_nationkey
    WHERE 
        cs.level < 3
),
CTE_Customer AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
MaxSpent AS (
    SELECT 
        MAX(total_spent) AS max_spent
    FROM 
        CTE_Customer
),
Filtered_Customers AS (
    SELECT 
        cc.c_custkey,
        cc.c_name,
        cc.order_count,
        cc.total_spent,
        ms.max_spent
    FROM 
        CTE_Customer cc
    CROSS JOIN 
        MaxSpent ms
    WHERE 
        cc.total_spent >= (ms.max_spent * 0.5)
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity_sold,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(l.l_discount) AS avg_discount,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice BETWEEN 100 AND 500
    AND l.l_shipdate >= DATE '1997-01-01'
GROUP BY 
    p.p_partkey, p.p_name, p.p_retailprice
HAVING 
    COALESCE(SUM(l.l_quantity), 0) > (
        SELECT AVG(total_quantity_sold * 0.75) 
        FROM (
            SELECT SUM(l.l_quantity) AS total_quantity_sold 
            FROM part p1
            JOIN lineitem l ON p1.p_partkey = l.l_partkey
            GROUP BY p1.p_partkey
        ) AS subquery
    )
ORDER BY 
    unique_customers DESC
LIMIT 10;
