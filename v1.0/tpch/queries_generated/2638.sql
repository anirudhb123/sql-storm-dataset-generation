WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_orders,
        c.total_spent,
        RANK() OVER (ORDER BY c.total_spent DESC) as rank
    FROM 
        CustomerOrders c
    WHERE 
        c.total_orders > 5
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    r.r_name AS supplier_region,
    ts.c_name AS top_customer,
    ts.total_spent
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey
LEFT JOIN 
    TopCustomers ts ON o.o_custkey = ts.c_custkey
LEFT JOIN 
    region r ON rs.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND (p.p_brand = 'BrandX' OR p.p_brand = 'BrandY')
    AND (p.p_retailprice > 100.00 OR p.p_comment IS NULL)
GROUP BY 
    ps.ps_partkey,
    p.p_name,
    r.r_name,
    ts.c_name,
    ts.total_spent
HAVING 
    SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC,
    supplier_region,
    top_customer;
