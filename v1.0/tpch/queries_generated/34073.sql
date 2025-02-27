WITH RECURSIVE region_suppliers AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        1 AS level
    FROM region r
    JOIN supplier s ON s.s_nationkey IN (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_regionkey = r.r_regionkey
    )
    UNION ALL
    SELECT 
        r.r_regionkey,
        r.r_name,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        rs.level + 1
    FROM region_suppliers rs
    JOIN supplier s ON s.s_nationkey IN (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_regionkey = rs.r_regionkey
    )
    WHERE rs.level < 3  -- Limit depth to avoid infinite recursion
), 
price_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
order_analysis AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS lineitem_count,
        MAX(l.l_shipdate) AS last_ship_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
)
SELECT 
    r.r_name AS region_name,
    ps.p_name AS part_name,
    ps.total_supply_cost,
    oa.total_revenue,
    rr.s_name AS supplier_name,
    rr.s_acctbal AS supplier_balance,
    (CASE 
        WHEN oa.total_revenue IS NULL THEN 'No Revenue'
        ELSE 'Has Revenue'
    END) AS revenue_status,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY oa.total_revenue DESC NULLS LAST) AS revenue_rank
FROM region r
LEFT OUTER JOIN region_suppliers rr ON r.r_regionkey = rr.r_regionkey
LEFT JOIN price_summary ps ON rr.s_suppkey = ps.p_partkey
LEFT JOIN order_analysis oa ON rr.s_suppkey = oa.o_orderkey
WHERE rr.s_acctbal IS NOT NULL 
  AND (oa.total_revenue > 10000 OR oa.total_revenue IS NULL)
ORDER BY r.r_name, revenue_rank;
