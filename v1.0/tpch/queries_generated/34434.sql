WITH RECURSIVE OrdersHierarchy AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, 1 AS hierarchy_level
    FROM orders o
    WHERE o.o_orderstatus = 'O' -- Active orders
    UNION ALL
    SELECT oh.o_orderkey, oh.o_orderstatus, oh.o_totalprice, oh.o_orderdate, hierarchy_level + 1
    FROM OrdersHierarchy oh
    JOIN orders o ON oh.o_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F' -- Completed orders
),
SupplierRanking AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
RegionSummary AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_acct_balance
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
OrderStatistics AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           COUNT(DISTINCT l.l_linenumber) AS line_item_count,
           AVG(l.l_quantity) AS avg_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY o.o_orderkey
)
SELECT rh.hierarchy_level, 
       os.o_orderkey, os.net_revenue, os.line_item_count, os.avg_quantity,
       rs.r_name, rs.nation_count, rs.total_acct_balance,
       sr.s_name, sr.total_supply_cost
FROM OrdersHierarchy rh
JOIN OrderStatistics os ON rh.o_orderkey = os.o_orderkey
JOIN RegionSummary rs ON rs.nation_count > 0
JOIN SupplierRanking sr ON sr.rank <= 5
WHERE os.net_revenue IS NOT NULL AND rs.total_acct_balance > 50000
ORDER BY rh.hierarchy_level, os.net_revenue DESC;
