
WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderpriority, 
        1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderpriority, 
        oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_custkey = oh.o_orderkey)
    WHERE oh.order_level < 10
),
SupplierStats AS (
    SELECT 
        p.p_partkey, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END) AS total_open_orders,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    s.s_name, 
    s.s_acctbal, 
    ss.supplier_count, 
    ss.avg_supply_cost,
    COALESCE(cos.total_open_orders, 0) AS total_open_orders,
    cos.total_orders,
    ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY ss.avg_supply_cost DESC) AS rank_within_nation
FROM supplier s
LEFT JOIN SupplierStats ss ON s.s_suppkey = ss.p_partkey
LEFT JOIN CustomerOrderStats cos ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
WHERE ss.supplier_count >= 1
AND (ss.avg_supply_cost < 50.00 OR ss.avg_supply_cost IS NULL)
ORDER BY s.s_name, total_open_orders DESC
LIMIT 5;
