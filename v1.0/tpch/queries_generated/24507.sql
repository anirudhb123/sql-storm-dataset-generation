WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS depth
    FROM nation
    WHERE n_nationkey IN (SELECT DISTINCT s_nationkey FROM supplier)
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.depth + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
customer_summary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent, 
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
part_supplier_info AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),
customer_order_rank AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        r.order_rank
    FROM customer c
    JOIN ranked_orders r ON c.c_custkey = r.o_orderkey
    WHERE r.order_rank <= 3
),
supply_summary AS (
    SELECT 
        nh.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part_supplier_info ps
    JOIN nation_hierarchy nh ON ps.p_partkey = nh.n_nationkey
    GROUP BY nh.n_name
)
SELECT 
    cs.c_name AS customer_name,
    ns.nation_name,
    COUNT(co.customer_order_rank) AS top_orders_count,
    CASE 
        WHEN ss.total_avail_qty IS NULL THEN 'No Supply'
        ELSE CAST(ss.total_avail_qty AS VARCHAR) || ' units available'
    END AS supply_status,
    ps.total_supply_cost - COALESCE(SUM(l.l_discount * l.l_extendedprice), 0) AS net_supply_cost
FROM customer_summary cs
FULL OUTER JOIN customer_order_rank co ON cs.c_custkey = co.c_custkey
LEFT JOIN supply_summary ss ON ss.nation_name = (SELECT r_name FROM region WHERE r_regionkey = co.o_orderkey)
LEFT JOIN lineitem l ON cs.c_custkey = l.l_orderkey AND l.l_returnflag = 'N'
GROUP BY cs.c_name, ns.nation_name, ss.total_avail_qty, ps.total_supply_cost
HAVING (COUNT(co.customer_order_rank) > 0 OR ss.total_avail_qty IS NOT NULL)
ORDER BY ns.nation_name, net_supply_cost DESC;
