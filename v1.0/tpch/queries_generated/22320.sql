WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank = 1
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment = 'BUILDING'
        AND o.o_orderstatus IS NOT NULL
),
OrderLineitem AS (
    SELECT 
        o.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        o.c_custkey
)
SELECT 
    co.c_custkey,
    co.c_name,
    COALESCE(SUM(ol.total_revenue), 0) AS total_revenue,
    COUNT(ts.s_suppkey) AS num_top_suppliers,
    CASE 
        WHEN COALESCE(SUM(ol.total_revenue), 0) > 100000 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    CustomerOrders co
LEFT JOIN 
    OrderLineitem ol ON co.c_custkey = ol.c_custkey
LEFT JOIN 
    TopSuppliers ts ON ts.s_suppkey IN (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        JOIN 
            part p ON ps.ps_partkey = p.p_partkey 
        WHERE 
            p.p_size BETWEEN 1 AND 10
    )
GROUP BY 
    co.c_custkey, co.c_name
HAVING 
    COUNT(DISTINCT ts.s_suppkey) > 0
ORDER BY 
    total_revenue DESC NULLS LAST;
