WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
TopRegions AS (
    SELECT 
        r.r_regionkey, 
        r.r_name,
        COALESCE(SUM(os.o_totalprice), 0) AS total_order_value
    FROM 
        region r
    LEFT JOIN 
        (SELECT 
            o.o_orderkey, 
            o.o_totalprice, 
            c.c_nationkey 
         FROM 
            orders o
         JOIN 
            customer c ON o.o_custkey = c.c_custkey 
         WHERE 
            c.c_acctbal IS NOT NULL 
            AND o.o_orderstatus = 'O'
        ) os ON os.c_nationkey = r.r_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    t.r_name AS region_name,
    COALESCE(t.total_order_value, 0) AS total_value,
    rs.s_name AS supplier_name,
    rs.total_avail_qty,
    COUNT(DISTINCT l.l_orderkey) AS unique_orders,
    SUM(CASE WHEN l.l_discount > 0.05 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS discounted_total
FROM 
    TopRegions t
LEFT JOIN 
    RankedSuppliers rs ON t.r_regionkey = rs.s_suppkey
LEFT JOIN 
    lineitem l ON l.l_suppkey = rs.s_suppkey
WHERE 
    t.total_order_value > (SELECT AVG(total_order_value) FROM TopRegions)
GROUP BY 
    t.r_name, rs.s_name, rs.total_avail_qty
HAVING 
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) = 0
ORDER BY 
    total_value DESC, discounted_total ASC;
