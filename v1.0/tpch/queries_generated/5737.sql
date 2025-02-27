WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopRegionNations AS (
    SELECT 
        n.n_regionkey,
        r.r_name AS region_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_regionkey, r.r_name
    ORDER BY 
        customer_count DESC
    LIMIT 5
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.region_name,
    s.s_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT co.c_custkey) AS loyal_customers
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    TopRegionNations trn ON r.r_name = trn.region_name
JOIN 
    CustomerOrderSummary co ON c.c_custkey = co.c_custkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    r.region_name, s.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
ORDER BY 
    revenue DESC;
