
WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_name = 'USA'
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_data AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS supply_part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
ranked_suppliers AS (
    SELECT 
        sd.*,
        RANK() OVER (ORDER BY sd.total_supply_cost DESC) as rank
    FROM supplier_data sd
),
customer_total AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus <> 'F'
    GROUP BY c.c_custkey
)
SELECT 
    nh.n_name,
    rs.s_name,
    rs.total_supply_cost,
    ct.total_spent,
    CASE 
        WHEN ct.total_spent IS NULL THEN 'No Orders'
        WHEN ct.total_spent > rs.total_supply_cost THEN 'High Spending Customer'
        ELSE 'Low Spending Customer'
    END AS spending_category
FROM nation_hierarchy nh
FULL OUTER JOIN ranked_suppliers rs ON nh.n_regionkey = (
    SELECT n_regionkey FROM nation WHERE n_nationkey = rs.s_suppkey LIMIT 1
)
LEFT JOIN customer_total ct ON rs.s_suppkey = ct.c_custkey
WHERE rs.rank <= 10
  AND (rs.total_supply_cost IS NOT NULL OR ct.total_spent IS NULL)
ORDER BY nh.n_name, rs.total_supply_cost DESC;
