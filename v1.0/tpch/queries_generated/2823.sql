WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1 WHERE s1.s_nationkey = s.s_nationkey)
), 
OrderLineItems AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY 
        o.o_orderkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(oi.total_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderLineItems oi ON o.o_orderkey = oi.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
SupplierOrderDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey AND ps.ps_suppkey = l.l_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_name
), 
CustomerAnalysis AS (
    SELECT 
        co.c_custkey, 
        co.c_name, 
        CASE 
            WHEN co.order_count = 0 THEN 'No Orders'
            WHEN co.total_spent > 1000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_type
    FROM 
        CustomerOrders co
)
SELECT 
    ra.s_name AS supplier_name,
    SUM(sod.total_quantity) AS total_quantity_supplied,
    SUM(sod.revenue) AS total_revenue,
    ca.customer_type
FROM 
    RankedSuppliers ra
LEFT JOIN 
    SupplierOrderDetails sod ON ra.s_suppkey = sod.ps_suppkey
JOIN 
    CustomerAnalysis ca ON ra.s_suppkey = (SELECT ps.ps_suppkey 
                                           FROM partsupp ps 
                                           JOIN lineitem l ON ps.ps_partkey = l.l_partkey
                                           WHERE l.l_suppkey = ra.s_suppkey
                                           GROUP BY ps.ps_suppkey
                                           ORDER BY SUM(l.l_quantity) DESC 
                                           LIMIT 1)
GROUP BY 
    ra.s_name, ca.customer_type
HAVING 
    total_revenue IS NOT NULL 
ORDER BY 
    total_revenue DESC;
