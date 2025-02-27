WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name,
    ps.ps_supplycost,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    r.r_name AS region_name,
    cs.total_spent,
    cs.total_orders,
    s_temp.s_name AS top_supplier
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    (SELECT s.s_nationkey, s.s_name 
     FROM RankedSuppliers s_temp 
     WHERE s_temp.rank = 1) s_temp ON n.n_nationkey = s_temp.s_nationkey
LEFT JOIN 
    CustomerOrderSummary cs ON c.c_custkey = cs.c_custkey
WHERE 
    p.p_retailprice > 50.00
GROUP BY 
    p.p_name, ps.ps_supplycost, r.r_name, cs.total_spent, cs.total_orders, s_temp.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    total_sales DESC, p.p_name ASC;
