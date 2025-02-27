WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        1 AS order_level
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= (cast('1998-10-01' as date) - INTERVAL '6 months')
    
    UNION ALL
    
    SELECT 
        co.c_custkey, 
        co.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        co.order_level + 1
    FROM 
        CustomerOrders co
    JOIN 
        orders o ON co.o_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate < (cast('1998-10-01' as date) - INTERVAL '6 months')
),
OrderDetails AS (
    SELECT 
        co.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT co.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        CustomerOrders co ON o.o_orderkey = co.o_orderkey
    GROUP BY 
        co.c_custkey
),
QualifiedSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        p.p_name,
        ps.ps_supplycost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(od.total_spent) AS avg_spent,
    SUM(CASE WHEN qs.rank = 1 THEN qs.ps_supplycost END) AS lowest_supplier_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    OrderDetails od ON c.c_custkey = od.c_custkey
LEFT JOIN 
    QualifiedSuppliers qs ON od.c_custkey = qs.ps_suppkey
GROUP BY 
    r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0 AND AVG(od.total_spent) IS NOT NULL
ORDER BY 
    region_name, nation_name;