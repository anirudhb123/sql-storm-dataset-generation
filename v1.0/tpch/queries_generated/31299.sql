WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, NULL::integer AS parent_regionkey
    FROM region
    WHERE r_name = 'AMERICA'
    
    UNION ALL
    
    SELECT r.regionkey, r.r_name, h.r_regionkey
    FROM region r
    JOIN RegionHierarchy h ON r.r_regionkey <> h.parent_regionkey
), 
AvgSupplierCost AS (
    SELECT ps_partkey, AVG(ps_supplycost) AS avg_supply_cost
    FROM partsupp
    GROUP BY ps_partkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        MAX(CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END) AS max_supplier_balance
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    ch.r_name AS region_name,
    c.c_name AS customer_name,
    ps.p_name AS part_name,
    ps.total_available,
    coalesce(cos.total_spent, 0) AS total_spent,
    coalesce(cos.total_orders, 0) AS total_orders,
    ac.avg_supply_cost,
    ps.max_supplier_balance,
    ROW_NUMBER() OVER (PARTITION BY ch.r_name ORDER BY cos.total_spent DESC) AS customer_rank
FROM RegionHierarchy ch
JOIN CustomerOrderSummary cos ON cos.c_custkey IN (
        SELECT c.c_custkey
        FROM customer c
        JOIN nation n ON c.c_nationkey = n.n_nationkey
        WHERE n.n_regionkey = ch.r_regionkey
    )
LEFT JOIN PartSupplierInfo ps ON ps.p_partkey IN (
        SELECT ps2.ps_partkey 
        FROM partsupp ps2
        JOIN supplier s ON ps2.ps_suppkey = s.s_suppkey
        WHERE s.s_acctbal > 1000
    )
JOIN AvgSupplierCost ac ON ps.p_partkey = ac.ps_partkey
WHERE ps.total_available > 0
ORDER BY ch.r_name, total_spent DESC;
