WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey IN (SELECT n_nationkey FROM supplier)
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(DISTINCT o.o_orderstatus) AS order_statuses
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)

SELECT 
    n.n_name AS nation_name,
    ss.s_name AS supplier_name,
    cs.c_name AS customer_name,
    cs.order_count,
    cs.total_spent,
    ss.total_cost,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        WHEN cs.total_spent < ss.total_cost THEN 'Low Spender'
        ELSE 'High Spender'
    END AS spending_category
FROM NationHierarchy n
LEFT JOIN SupplierStats ss ON n.n_nationkey = ss.s_suppkey
LEFT JOIN CustomerOrders cs ON n.n_nationkey = cs.c_custkey
WHERE (ss.total_cost IS NOT NULL OR cs.order_count > 0)
ORDER BY n.n_name, ss.total_cost DESC, cs.total_spent DESC;
