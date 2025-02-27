WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') OR o.o_orderstatus IS NULL
),
PartSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    ps.p_partkey,
    SUM(ps.total_revenue) AS estimated_revenue,
    CASE 
        WHEN rs.rnk = 1 THEN 'Top Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_status,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    CASE 
        WHEN SUM(ps.total_revenue) - (SELECT AVG(total_revenue) FROM PartSales) > 0 THEN 'Above Average'
        ELSE 'Below Average'
    END AS revenue_comparison
FROM 
    PartSales ps
LEFT JOIN 
    CustomerOrders co ON co.o_orderkey = (SELECT MIN(o.o_orderkey) FROM CustomerOrders o WHERE o.o_custkey = co.c_custkey)
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = (SELECT MIN(s.s_suppkey) FROM RankedSuppliers s WHERE s.rnk <= 3)
GROUP BY 
    c.c_custkey, ps.p_partkey, rs.rnk
HAVING 
    SUM(ps.total_revenue) > 50000 OR SUM(ps.total_revenue) IS NULL
ORDER BY 
    CASE 
        WHEN customer_name = 'Unknown Customer' THEN 1
        ELSE 0
    END, estimated_revenue DESC;
