WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ps.ps_supplycost, 
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size BETWEEN 1 AND 10
), 
TopParts AS (
    SELECT 
        p_partkey, 
        p_name, 
        p_retailprice, 
        ps_supplycost
    FROM 
        RankedParts
    WHERE 
        rank = 1
), 
CustomerRanked AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS cust_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name, 
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
    CASE 
        WHEN cr.cust_rank IS NULL THEN 'New Customer'
        ELSE 'Loyal Customer'
    END AS customer_status,
    r.r_name AS region_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM 
    TopParts p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerRanked cr ON c.c_custkey = cr.c_custkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
    AND (DATEDIFF(NOW(), o.o_orderdate) > 30 OR o.o_orderdate < '2022-01-01')
GROUP BY 
    p.p_name, cr.cust_rank, r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    total_sales DESC 
FETCH FIRST 10 ROWS ONLY;
