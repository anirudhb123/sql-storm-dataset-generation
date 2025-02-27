WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_nationkey IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS item_count,
        MAX(l.l_shipdate) AS latest_shipdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerRank AS (
    SELECT 
        c.c_custkey,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(o.o_totalprice) DESC) AS rank,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_mktsegment
),
NationSummary AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name
)
SELECT 
    r.r_name,
    ns.supplier_count,
    ns.total_supply_cost,
    COALESCE(cr.total_spent, 0) AS total_spent,
    o.total_revenue,
    o.item_count,
    oh.level AS supplier_hierarchy_level
FROM region r
LEFT JOIN NationSummary ns ON r.r_regionkey = ns.n_nationkey
LEFT JOIN CustomerRank cr ON cr.custkey = (SELECT c.c_custkey FROM customer c WHERE cr.rank = 1)
LEFT JOIN OrderStats o ON o.o_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o WHERE o.o_orderstatus = 'O')
LEFT JOIN SupplierHierarchy oh ON ns.supplier_count IS NOT NULL
WHERE ns.total_supply_cost > (SELECT AVG(total_supply_cost) FROM NationSummary)
ORDER BY r.r_name, total_spent DESC;
