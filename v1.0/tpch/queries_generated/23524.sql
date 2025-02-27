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
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
NotOrderedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderkey IS NULL
),
MinimumLineItem AS (
    SELECT 
        l.l_orderkey, 
        MIN(l.l_extendedprice) AS min_price
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        SUM(CASE WHEN l.l_quantity > 10 THEN 1 ELSE 0 END) AS high_quantity_count,
        AVG(l.l_discount) AS avg_discount
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    c.c_name,
    COALESCE(o.total_orders, 0) AS order_count,
    COALESCE(o.total_spent, 0) AS total_spent,
    ss.s_name AS best_supplier,
    ss.high_quantity_count,
    ss.avg_discount
FROM 
    NotOrderedCustomers c
LEFT JOIN 
    CustomerOrders o ON c.c_custkey = o.c_custkey
LEFT JOIN (
    SELECT 
        s.s_name,
        sp.high_quantity_count,
        sp.avg_discount
    FROM 
        RankedSuppliers rs 
    JOIN 
        SupplierPerformance sp ON rs.s_suppkey = sp.s_suppkey
    WHERE 
        rs.rnk = 1
) ss ON ss.high_quantity_count IS NOT NULL
ORDER BY 
    c.c_name ASC;
