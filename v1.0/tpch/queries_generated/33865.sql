WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS depth
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.depth + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
SupplierRanked AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
PartSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_quantity,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    n.n_name,
    s.s_name AS supplier_name,
    ps.p_name AS part_name,
    ps.total_quantity,
    ps.avg_cost,
    cos.total_orders,
    cos.total_spent,
    COALESCE(s.rank, 0) AS supplier_rank
FROM NationHierarchy n
LEFT JOIN SupplierRanked s ON n.n_nationkey = s.s_nationkey AND s.rank = 1
JOIN PartSummary ps ON s.s_suppkey = ps.p_partkey
JOIN CustomerOrderSummary cos ON cos.total_orders > 0
WHERE 
    ps.total_quantity > 1000
    AND cos.total_spent IS NOT NULL
ORDER BY n.n_name, s.s_name;
