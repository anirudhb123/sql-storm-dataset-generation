WITH Supplier_Costs AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name, s.s_nationkey
),
Customer_Segment AS (
    SELECT 
        c.c_custkey,
        c.c_mktsegment,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_mktsegment
),
LineItem_Summary AS (
    SELECT 
        l.l_orderkey,
        COUNT(l.l_linenumber) AS total_lines,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
Nation_Aggregate AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)

SELECT 
    p.p_name,
    p.p_retailprice,
    COALESCE(sc.total_supply_cost, 0) AS total_supply_cost,
    cs.order_count,
    las.total_lines,
    las.net_revenue,
    na.unique_suppliers,
    na.avg_account_balance,
    CASE 
        WHEN cs.order_count IS NULL THEN 'No Orders'
        WHEN las.net_revenue > 1000 THEN 'High Revenue'
        ELSE 'Regular Revenue'
    END AS revenue_status
FROM part p
LEFT JOIN Supplier_Costs sc ON p.p_partkey = sc.ps_partkey
LEFT JOIN Customer_Segment cs ON cs.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = sc.s_nationkey LIMIT 1)
LEFT JOIN LineItem_Summary las ON las.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey LIMIT 1)
LEFT JOIN Nation_Aggregate na ON na.n_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = sc.s_nationkey LIMIT 1)
WHERE p.p_retailprice > (
    SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 30
)
ORDER BY p.p_name, total_supply_cost DESC;
