WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_amount
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 10000
    GROUP BY 
        c.c_custkey, c.c_name
),
Top10Customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(c.total_orders, 0) AS total_orders,
        COALESCE(c.avg_order_amount, 0) AS avg_order_amount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(c.avg_order_amount, 0) DESC) AS rn
    FROM 
        CustomerOrders c
)
SELECT 
    p.p_partkey,
    p.p_name,
    r.r_name AS region,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    COALESCE(tc.total_orders, 0) AS total_orders,
    COALESCE(tc.avg_order_amount, 0) AS avg_order_amount,
    (l.l_extendedprice * (1 - l.l_discount)) AS net_price
FROM 
    part p
LEFT JOIN 
    partsupp ps ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    supplier rs ON ps.ps_suppkey = rs.s_suppkey AND rs.s_acctbal >= 5000
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    nation n ON n.n_nationkey = rs.s_nationkey
LEFT JOIN 
    region r ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    Top10Customers tc ON tc.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey LIMIT 1)
WHERE 
    p.p_size BETWEEN 1 AND 20
    AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
    AND p.p_comment NOT LIKE '%obsolete%'
ORDER BY 
    region, net_price DESC;
