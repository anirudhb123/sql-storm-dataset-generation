WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_totalprice IS NOT NULL
),
supplier_part_info AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        LAG(ps.ps_supplycost, 1, 0) OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS prev_supplycost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_size > 0
),
filtered_lineitems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM lineitem l
    WHERE l.l_discount BETWEEN 0 AND 0.1
    GROUP BY l.l_orderkey
),
nation_counts AS (
    SELECT 
        n.n_nationkey,
        COUNT(DISTINCT c.c_custkey) AS cust_count
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey
)
SELECT 
    r.r_regionkey,
    p.p_brand,
    AVG(COALESCE(s.ps_availqty, 0)) AS avg_avail_qty,
    SUM(f.net_revenue) AS total_net_revenue,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    nc.cust_count,
    p.p_mfgr,
    CASE 
        WHEN AVG(s.ps_supplycost) IS NULL THEN 'No Cost Data'
        WHEN AVG(s.ps_supplycost) < 100 THEN 'Low Cost'
        ELSE 'High Cost'
    END AS cost_category
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN ranked_orders ro ON c.c_custkey = ro.o_custkey OR ro.o_orderkey IS NULL
LEFT JOIN supplier_part_info s ON s.ps_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps
    WHERE ps.ps_availqty > (
        SELECT AVG(ps2.ps_availqty) 
        FROM partsupp ps2 
        WHERE ps2.ps_supplycost < 50
    )
)
FULL OUTER JOIN filtered_lineitems f ON ro.o_orderkey = f.l_orderkey
FULL OUTER JOIN nation_counts nc ON n.n_nationkey = nc.n_nationkey
GROUP BY r.r_regionkey, p.p_brand, nc.cust_count, p.p_mfgr
HAVING COUNT(DISTINCT ro.o_orderkey) > 5
ORDER BY r.r_regionkey, total_net_revenue DESC, avg_avail_qty ASC;
