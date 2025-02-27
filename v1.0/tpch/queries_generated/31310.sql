WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_suppkey IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5 -- Limiting recursion depth
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS line_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) as rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerAnalysis AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(os.total_revenue), 0) AS total_spent,
        COUNT(os.o_orderkey) AS order_count,
        CASE
            WHEN COUNT(os.o_orderkey) = 0 THEN 'No Orders' 
            ELSE 'Transactional'
        END AS customer_status
    FROM customer c
    LEFT JOIN OrderSummary os ON c.c_custkey = os.o_orderkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_name,
    ps.ps_availqty,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    (SELECT COUNT(*) FROM SupplierHierarchy) AS total_suppliers,
    (SELECT MAX(total_spent) FROM CustomerAnalysis) AS max_customer_spent,
    CASE 
        WHEN ps.ps_availqty IS NULL THEN 'Unavailable'
        ELSE 'Available'
    END AS availability_status
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY p.p_name, ps.ps_availqty
HAVING SUM(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY total_supply_cost DESC
LIMIT 10;
