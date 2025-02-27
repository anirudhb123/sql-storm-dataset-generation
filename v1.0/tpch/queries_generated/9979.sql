WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FrequentOrders AS (
    SELECT 
        o.o_custkey, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
    HAVING 
        COUNT(o.o_orderkey) > 5
),
ProductSales AS (
    SELECT 
        l.l_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        l.l_partkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    rs.s_name AS supplier_name, 
    fs.order_count,
    ps.total_revenue
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rank = 1
JOIN 
    FrequentOrders fs ON fs.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA'))
WHERE 
    p.p_retailprice > 50.00 
ORDER BY 
    ps.total_revenue DESC
LIMIT 10;
