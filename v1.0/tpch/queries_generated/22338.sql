WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE c.c_acctbal IS NOT NULL AND o.o_orderdate >= '1995-01-01'
),
AvailableParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
PartSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        COALESCE(p.p_brand, 'UNKNOWN') AS brand,
        AVG(l.l_discount) AS avg_discount,
        COUNT(l.l_orderkey) AS total_orders
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr
    HAVING AVG(l.l_discount) > 0.1 OR COUNT(l.l_orderkey) > 5
)
SELECT 
    r.r_name,
    ns.n_name AS supplier_nation,
    COUNT(DISTINCT po.o_orderkey) AS total_orders,
    SUM(COALESCE(ps.total_avail_qty, 0)) AS total_available_quantity,
    SUM(ps.total_supply_cost) AS total_supply_cost,
    STRING_AGG(CONCAT_WS(' - ', ps.p_name, po.o_orderdate)::text, '; ') AS order_details
FROM RankedOrders po
LEFT JOIN AvailableParts ps ON po.o_orderkey = ps.ps_partkey
JOIN nation ns ON ns.n_nationkey = po.c_nationkey
JOIN region r ON r.r_regionkey = ns.n_regionkey
WHERE po.order_rank <= 10 
AND EXISTS (
    SELECT 1 
    FROM lineitem l 
    WHERE l.l_orderkey = po.o_orderkey 
    AND l.l_discount IS NOT NULL
)
GROUP BY r.r_name, ns.n_name
HAVING total_orders > 0
ORDER BY total_supply_cost DESC, r.r_name ASC;
