WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, 1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = 
        (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA'))
    WHERE oh.order_level < 5
),
SupplierAggregates AS (
    SELECT p.p_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY p.p_partkey
),
CustomerOrderCounts AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
PartPopularity AS (
    SELECT p.p_name, COUNT(l.l_orderkey) AS sales_count
    FROM lineitem l
    JOIN part p ON l.l_partkey = p.p_partkey
    GROUP BY p.p_name
)
SELECT 
    c.c_name,
    COALESCE(coc.order_count, 0) AS order_count,
    ph.p_name,
    COALESCE(SA.total_supply_cost, 0) AS total_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY ph.sales_count DESC) AS popularity_rank
FROM customer c
LEFT JOIN CustomerOrderCounts coc ON c.c_custkey = coc.c_custkey
LEFT JOIN PartPopularity ph ON ph.sales_count > 5
LEFT JOIN SupplierAggregates SA ON ph.p_name LIKE CONCAT('%', SUBSTRING(c.c_name, 1, 3), '%')
WHERE c.c_acctbal IS NOT NULL
AND (
    EXISTS (SELECT 1 FROM OrderHierarchy oh WHERE oh.o_orderkey = coc.order_count)
    OR c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name IN ('USA', 'CANADA'))
)
ORDER BY c.c_name, popularity_rank DESC;
