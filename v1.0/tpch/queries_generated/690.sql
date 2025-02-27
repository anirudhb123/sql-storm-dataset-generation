WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        l.l_shipdate,
        l.l_shipmode,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS line_number
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
)
SELECT 
    p.p_name,
    r.r_name AS region,
    cs.c_name AS customer_name,
    od.o_orderkey,
    SUM(od.l_extendedprice * (1 - od.l_discount)) AS net_revenue,
    COUNT(od.line_number) AS item_count,
    MIN(od.l_shipdate) AS first_ship_date,
    MAX(od.l_shipdate) AS last_ship_date,
    COALESCE(rs.s_name, 'No Supplier') AS top_supplier
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
JOIN 
    OrderDetails od ON p.p_partkey = od.l_partkey
JOIN 
    CustomerOrders cs ON cs.total_orders > 5
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = s.s_suppkey AND rs.rank = 1
WHERE 
    p.p_retailprice > 50
GROUP BY 
    p.p_name, r.r_name, cs.c_name, od.o_orderkey, rs.s_name
ORDER BY 
    net_revenue DESC, item_count DESC;
