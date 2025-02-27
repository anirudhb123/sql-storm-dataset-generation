WITH RECURSIVE SalesCTE AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
    UNION ALL
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        s.total_spent + l.l_extendedprice * (1 - l.l_discount)
    FROM 
        SalesCTE s
    JOIN 
        orders o ON s.o_orderkey = o.o_orderkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'R'
), RankedSales AS (
    SELECT 
        c.c_name,
        SUM(s.total_spent) AS total_spent,
        RANK() OVER (ORDER BY SUM(s.total_spent) DESC) AS rank
    FROM 
        SalesCTE s
    JOIN 
        customer c ON s.c_custkey = c.c_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    r.r_name,
    COALESCE(n.n_name, '(no nation)') AS nation,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice) AS avg_price,
    MAX(l.l_discount) AS max_discount
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    r.r_name LIKE '%West%'
    AND (n.n_name IS NULL OR s.s_acctbal < 500.00)
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    total_spent DESC NULLS LAST;
