WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name IN ('USA', 'Germany')
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
OrderLineItem AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    c.c_name,
    c.total_orders,
    c.total_spent,
    COALESCE(SUM(ol.revenue), 0) AS total_revenue,
    s.s_name AS top_supplier
FROM 
    CustomerOrders c
LEFT JOIN 
    OrderLineItem ol ON c.total_orders > 10 AND ol.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
LEFT JOIN 
    RankedSuppliers s ON s.rank = 1 AND s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 20))
WHERE 
    c.total_spent IS NOT NULL
GROUP BY 
    c.c_name, c.total_orders, c.total_spent, s.s_name
ORDER BY 
    total_revenue DESC;
