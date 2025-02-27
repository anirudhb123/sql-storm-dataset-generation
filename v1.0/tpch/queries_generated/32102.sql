WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_availqty > 0)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
CustomerSummary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent, 
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name 
),
RegionPerformance AS (
    SELECT 
        r.r_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS orders_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
    JOIN lineitem l ON l.l_partkey = ps.ps_partkey
    JOIN orders o ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY r.r_name
)
SELECT 
    cs.c_name,
    cs.total_spent,
    rh.level AS supplier_level,
    rp.r_name,
    rp.total_sales,
    rp.orders_count
FROM CustomerSummary cs
LEFT JOIN SupplierHierarchy rh ON rh.s_nationkey = cs.c_nationkey
LEFT JOIN RegionPerformance rp ON rp.r_name IS NOT NULL
WHERE cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSummary)
ORDER BY cs.total_spent DESC, rp.total_sales ASC
LIMIT 10;
