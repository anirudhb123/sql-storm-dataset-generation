WITH RECURSIVE OrderCTE AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'F'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        oc.order_level + 1
    FROM orders o
    JOIN OrderCTE oc ON o.o_custkey = oc.o_orderkey
    WHERE o.o_orderstatus = 'P'
),
PartSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count,
        MAX(l.l_shipdate) AS last_ship_date
    FROM lineitem l
    GROUP BY l.l_orderkey
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name,
        COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
)

SELECT 
    ns.n_name,
    ns.supplier_count,
    ps.p_name,
    ps.total_avail_qty,
    ls.total_revenue,
    ls.part_count,
    RANK() OVER (PARTITION BY ns.n_name ORDER BY ls.total_revenue DESC) AS revenue_rank,
    CASE
        WHEN ls.part_count > 10 THEN 'High variety'
        WHEN ls.part_count = 10 THEN 'Medium variety'
        ELSE 'Low variety'
    END AS variety_level
FROM NationRegion ns
JOIN PartSummary ps ON ns.supplier_count > 0
JOIN LineItemSummary ls ON ns.n_nationkey = ls.l_orderkey
WHERE ns.supplier_count IS NOT NULL
AND (ls.total_revenue > 10000 OR ls.part_count > 5)
ORDER BY revenue_rank, ns.n_name, ls.total_revenue DESC;
