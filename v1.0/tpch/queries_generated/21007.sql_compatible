
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_discount,
        l.l_extendedprice,
        CASE
            WHEN l.l_returnflag = 'R' THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status,
        COALESCE(NULLIF(l.l_comment, ''), 'No Comments') AS item_comment
    FROM 
        lineitem l
    WHERE 
        l.l_quantity > 0 OR l.l_discount > 0
)
SELECT 
    r.r_name,
    COALESCE(SUM(f.l_extendedprice * (1 - f.l_discount)), 0) AS total_revenue,
    AVG(co.total_spent) AS avg_customer_spent,
    COUNT(DISTINCT rs.s_suppkey) AS unique_suppliers,
    STRING_AGG(DISTINCT rs.s_name, ', ') AS supplier_names,
    COUNT(DISTINCT f.l_orderkey) FILTER (WHERE f.return_status = 'Returned') AS returned_items
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN 
    FilteredLineItems f ON f.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN 
    RankedSuppliers rs ON rs.rnk = 1
WHERE 
    r.r_name LIKE '%e%' 
GROUP BY 
    r.r_name, r.r_regionkey
HAVING 
    SUM(f.l_extendedprice * (1 - f.l_discount)) IS NOT NULL
ORDER BY 
    total_revenue DESC;
