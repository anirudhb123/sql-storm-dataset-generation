WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        YEAR(o.o_orderdate) AS order_year
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    cs.c_name AS customer_name,
    os.total_revenue,
    cs.total_spent,
    cs.order_count,
    r.r_name AS region_name
FROM 
    partsupp ps
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rank = 1
JOIN 
    orders o ON ps.ps_partkey = l.l_partkey
JOIN 
    OrderSummary os ON o.o_orderkey = os.o_orderkey
JOIN 
    CustomerSummary cs ON o.o_custkey = cs.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    (os.total_revenue > 5000 OR cs.total_spent IS NULL)
    AND p.p_retailprice > (SELECT AVG(p_retailprice) FROM part WHERE p_size > 10)
ORDER BY 
    total_revenue DESC, cs.total_spent ASC;
