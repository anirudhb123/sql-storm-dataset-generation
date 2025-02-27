WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
AggregatedSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2022-01-01' OR o.o_orderdate IS NULL
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, a.total_spent
    FROM customer c
    JOIN AggregatedSales a ON c.c_custkey = a.c_custkey
    WHERE a.total_spent > (SELECT AVG(total_spent) FROM AggregatedSales)
),
RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        RANK() OVER (PARTITION BY p.p_mfgr ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr
)
SELECT 
    s.s_suppkey,
    s.s_name,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY total_revenue DESC) AS national_rank,
    CASE WHEN p.rank BETWEEN 1 AND 5 THEN 'Top 5' ELSE 'Others' END AS part_rank_group
FROM supplier s
LEFT JOIN lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN RankedParts p ON l.l_partkey = p.p_partkey
WHERE l.l_shipdate >= '2023-01-01' AND (s.s_comment IS NULL OR s.s_comment LIKE '%VIP%')
GROUP BY s.s_suppkey, s.s_name, p.rank
HAVING COUNT(DISTINCT l.l_orderkey) > 10
ORDER BY total_revenue DESC, s.s_name ASC;
