WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(l.l_orderkey) AS total_orders,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_order_value
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        total_avail_qty, 
        total_orders, 
        avg_order_value,
        RANK() OVER (ORDER BY avg_order_value DESC) AS rank
    FROM 
        SupplierStats s
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    ts.s_name AS supplier_name,
    ts.total_avail_qty,
    ts.total_orders,
    ts.avg_order_value
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    TopSuppliers ts ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = ts.s_suppkey)
WHERE 
    r.r_name IS NOT NULL 
    AND ts.avg_order_value > (
        SELECT 
            AVG(avg_order_value) 
        FROM 
            TopSuppliers
    )
ORDER BY 
    r.r_name,
    ts.rank ASC;
