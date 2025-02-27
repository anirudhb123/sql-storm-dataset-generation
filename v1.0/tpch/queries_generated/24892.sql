WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS acct_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
AvailableParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Completed'
            ELSE 'Pending'
        END AS order_status
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
)
SELECT 
    r.r_name AS region_name,
    p.p_name AS part_name,
    COALESCE(a.total_avail_qty, 0) AS total_available_quantity,
    COALESCE(a.avg_supply_cost, 0.00) AS average_supply_cost,
    COUNT(DISTINCT fo.o_orderkey) AS total_orders,
    SUM(fo.o_totalprice) AS total_revenue,
    STRING_AGG(DISTINCT s.s_name || ' ' || s.s_acctbal ORDER BY s.s_acctbal DESC) AS supplier_list
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.acct_rank = 1
LEFT JOIN 
    AvailableParts a ON s.s_suppkey = a.p_partkey
LEFT JOIN 
    FilteredOrders fo ON fo.o_orderkey = (SELECT l.l_orderkey 
                                           FROM lineitem l 
                                           WHERE l.l_partkey = a.p_partkey 
                                           AND l.l_returnflag = 'N' 
                                           ORDER BY l.l_shipdate 
                                           LIMIT 1)
WHERE 
    (s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000)
    OR (rs.acct_rank IS NULL AND a.avg_supply_cost < (SELECT AVG(ps2.ps_supplycost) 
                                                        FROM partsupp ps2 
                                                        WHERE ps2.ps_supplycost IS NOT NULL))
GROUP BY 
    r.r_name, p.p_name
HAVING 
    COUNT(DISTINCT fo.o_orderkey) > 0
ORDER BY 
    r.r_name, total_available_quantity DESC;
