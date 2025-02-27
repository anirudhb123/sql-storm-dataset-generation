WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal, 1 AS depth
    FROM customer
    WHERE c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.depth + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_custkey = ch.c_custkey
    WHERE c.c_acctbal > 1000
),
SupplierStatistics AS (
    SELECT 
        s.n_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM supplier s
    INNER JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.n_nationkey
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING SUM(ps.ps_supplycost) > 10000
)
SELECT 
    c.c_name AS customer_name,
    c.c_acctbal AS customer_balance,
    r.r_name AS region_name,
    ss.total_suppliers,
    ss.avg_account_balance,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY c.c_acctbal DESC) AS rank
FROM customer c
JOIN CustomerHierarchy ch ON c.c_custkey = ch.c_custkey
JOIN SupplierStatistics ss ON c.c_nationkey = ss.n_nationkey
FULL OUTER JOIN TopRegions r ON ss.n_nationkey = r.r_regionkey
WHERE 
    c.c_acctbal IS NOT NULL
    AND r.total_supply_cost IS NOT NULL
    AND (c.c_acctbal > 5000 OR r.total_supply_cost < 20000)
ORDER BY r.r_name, c.c_acctbal DESC;
