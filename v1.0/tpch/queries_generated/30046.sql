WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, 1 AS level
    FROM customer
    WHERE c_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
),
SalesData AS (
    SELECT 
        o.o_orderkey,
        c.c_name AS customer_name,
        l.l_quantity * l.l_extendedprice * (1 - l.l_discount) AS revenue,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_order
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
        AND l.l_discount BETWEEN 0.05 AND 0.20
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_supplycost,
        p.p_size,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey, ps.ps_supplycost, p.p_size
)
SELECT 
    ch.level,
    ch.c_name,
    ns.n_name,
    COALESCE(SUM(sd.revenue), 0) AS total_revenue,
    AVG(sc.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM CustomerHierarchy ch
LEFT JOIN SalesData sd ON ch.c_custkey = sd.o_orderkey
LEFT JOIN nation ns ON ch.c_nationkey = ns.n_nationkey
LEFT JOIN SupplierCosts sc ON sc.ps_partkey IN (
    SELECT ps_partkey FROM partsupp 
    WHERE ps_suppkey IN (
        SELECT s_suppkey FROM supplier WHERE s_acctbal > 1000
    )
)
LEFT JOIN part p ON p.p_partkey = sc.ps_partkey
GROUP BY ch.level, ch.c_name, ns.n_name
HAVING COALESCE(SUM(sd.revenue), 0) > 5000
ORDER BY level, total_revenue DESC;
