WITH RECURSIVE region_hierarchy AS (
    SELECT r_regionkey, r_name, r_comment, 0 as level
    FROM region
    WHERE r_regionkey = 1

    UNION ALL

    SELECT r.r_regionkey, r.r_name, r.r_comment, rh.level + 1
    FROM region r
    JOIN region_hierarchy rh ON r.r_regionkey = rh.level + 1
),
ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
),
filtered_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size > 20
    GROUP BY p.p_partkey, p.p_name
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
order_summary AS (
    SELECT 
        l.l_orderkey,
        COUNT(DISTINCT l.l_partkey) AS part_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    rh.r_name,
    ps.p_name,
    cs.total_orders,
    cs.total_spent,
    os.part_count,
    os.revenue,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        WHEN cs.total_spent > 1000 THEN 'High Spending'
        ELSE 'Regular Customer'
    END AS customer_category,
    COALESCE(ss.s_name, 'Unknown Supplier') as supplier_name
FROM filtered_parts ps
JOIN customer_orders cs ON ps.p_partkey = cs.c_custkey 
LEFT JOIN ranked_suppliers ss ON cs.total_orders = ss.rank
JOIN order_summary os ON cs.total_orders = os.l_orderkey
JOIN region_hierarchy rh ON cs.total_orders = rh.level
WHERE rh.level < 3
ORDER BY rh.r_name, cs.total_spent DESC;
