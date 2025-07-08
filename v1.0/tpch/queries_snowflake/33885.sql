WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS hierarchy_level
    FROM customer c
    WHERE c.c_acctbal > 10000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.hierarchy_level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.hierarchy_level < 5
), PriceRank AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    p.p_name,
    rh.c_name AS customer_name,
    ro.total_revenue,
    pr.total_supply_cost,
    COALESCE(pr.total_supply_cost / NULLIF(ro.total_revenue, 0), 0) AS supply_to_revenue_ratio,
    CASE 
        WHEN ro.total_revenue > 10000 THEN 'High Revenue'
        WHEN ro.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM part p
LEFT OUTER JOIN PriceRank pr ON p.p_partkey = pr.ps_partkey AND pr.rank = 1
INNER JOIN RecentOrders ro ON p.p_partkey = ro.o_orderkey
INNER JOIN CustomerHierarchy rh ON rh.c_custkey = ro.o_orderkey
WHERE p.p_retailprice > 50.00 
AND (p.p_comment LIKE '%premium%' OR p.p_comment IS NULL)
ORDER BY supply_to_revenue_ratio DESC, revenue_category;