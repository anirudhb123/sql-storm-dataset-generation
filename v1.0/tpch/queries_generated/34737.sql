WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, 1 AS level
    FROM customer
    WHERE c_acctbal > (SELECT AVG(c_acctbal) FROM customer)

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 5
),
RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 1000000
),
CompoundQuery AS (
    SELECT DISTINCT 
        p.p_partkey,
        p.p_name,
        ph.total_supply_value,
        hh.c_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ph.total_supply_value DESC) AS part_rank
    FROM part p
    LEFT JOIN HighValueSuppliers ph ON p.p_partkey = ph.s_suppkey
    LEFT JOIN CustomerHierarchy hh ON p.p_partkey = hh.c_custkey
)
SELECT
    cq.p_partkey,
    cq.p_name,
    COALESCE(cq.total_supply_value, 0) AS total_supply_value,
    cq.c_name,
    CASE 
        WHEN cq.part_rank IS NOT NULL THEN 'Ranked'
        ELSE 'Not Ranked'
    END AS ranking_status
FROM CompoundQuery cq
WHERE cq.total_supply_value IS NOT NULL
ORDER BY cq.total_supply_value DESC
LIMIT 10;
