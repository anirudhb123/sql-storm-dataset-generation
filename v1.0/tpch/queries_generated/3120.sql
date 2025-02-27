WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        DENSE_RANK() OVER (ORDER BY SUM(ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS orders_count,
        COALESCE(SUM(ho.total_value), 0) AS high_value_orders_total
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        HighValueOrders ho ON o.o_orderkey = ho.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cr.c_custkey,
    cr.c_name,
    cr.orders_count,
    s.supp_name,
    rs.total_avail_qty,
    CASE 
        WHEN cr.high_value_orders_total > 0 THEN 'Yes'
        ELSE 'No'
    END AS has_high_value_order
FROM 
    CustomerOrders cr
LEFT JOIN 
    RankedSuppliers rs ON rs.supplier_rank <= cr.orders_count
LEFT JOIN 
    (SELECT 
         s_name AS supp_name, 
         ROW_NUMBER() OVER (ORDER BY s_acctbal DESC) AS rank
     FROM 
         supplier) s ON s.rank <= 5
ORDER BY 
    cr.orders_count DESC,
    rs.total_avail_qty DESC;
