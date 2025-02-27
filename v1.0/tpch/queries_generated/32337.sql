WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        1 AS hierarchy_level
    FROM orders o
    WHERE o.o_orderstatus = 'F'  -- Filter for completed orders
    UNION ALL
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        oh.hierarchy_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS parts_supplied,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
PerformanceBenchmark AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.order_count,
        co.total_spent,
        sp.parts_supplied,
        sp.total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM CustomerOrderStats co
    JOIN customer c ON co.c_custkey = c.c_custkey
    LEFT JOIN SupplierParts sp ON sp.s_suppkey = (SELECT ps.ps_suppkey 
                                                   FROM partsupp ps 
                                                   JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
                                                   WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
                                                   LIMIT 1)  -- Example using correlated subquery
)
SELECT 
    pb.c_custkey,
    pb.c_name,
    pb.order_count,
    pb.total_spent,
    pb.parts_supplied,
    pb.total_supply_cost,
    RANK() OVER (ORDER BY pb.total_spent DESC) AS customer_rank
FROM PerformanceBenchmark pb
WHERE pb.total_spent IS NOT NULL
AND EXISTS (
    SELECT 1 
    FROM nation n 
    WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = pb.c_custkey)
    AND n.n_name LIKE '%United%'
)
ORDER BY pb.total_spent DESC, pb.c_name ASC;
