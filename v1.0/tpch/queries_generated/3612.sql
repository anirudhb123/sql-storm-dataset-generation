WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS ranking
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name, 
        s.n_nationkey
), 
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s_acctbal) 
            FROM supplier 
            WHERE s_acctbal IS NOT NULL
        )
), 
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, 
        o.o_custkey
)

SELECT 
    ps.p_partkey,
    p.p_name,
    COALESCE(s.s_name, 'Not Available') AS supplier_name,
    s_stats.total_available_qty,
    s_stats.total_supply_cost,
    r.n_name AS nation_name,
    CASE 
        WHEN r.n_name IS NOT NULL THEN 'Available'
        ELSE 'Unavailable'
    END AS supplier_status,
    recent_orders.total_order_value AS recent_order_value
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation r ON s.s_nationkey = r.n_nationkey
LEFT JOIN 
    SupplierStats s_stats ON s.s_suppkey = s_stats.s_suppkey
LEFT JOIN 
    RecentOrders recent_orders ON recent_orders.o_custkey = s.c_nationkey
WHERE 
    (p.p_size > 10 AND p.p_retailprice < 50.00)
    OR (p.p_comment LIKE '%special%' AND s_stats.ranking <= 5)
ORDER BY 
    p.p_partkey, supplier_status;
