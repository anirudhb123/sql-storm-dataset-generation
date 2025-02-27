WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, 1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey AND o.o_orderdate > oh.o_orderdate
    WHERE o.o_orderstatus = 'O'
),
AggregateSupplier AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
CustomerWithRank AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank_acctbal
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS avg_supplier_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_linenumber) AS item_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice,
       cs.c_name, cs.c_acctbal, cs.rank_acctbal,
       ns.n_name, ns.supplier_count, ns.avg_supplier_acctbal,
       lis.item_count, lis.total_revenue
FROM OrderHierarchy oh
JOIN CustomerWithRank cs ON oh.o_custkey = cs.c_custkey
JOIN LineItemSummary lis ON oh.o_orderkey = lis.l_orderkey
JOIN NationSummary ns ON cs.c_nationkey = ns.n_nationkey
WHERE ns.supplier_count > 0 AND ns.avg_supplier_acctbal IS NOT NULL
ORDER BY oh.o_orderdate DESC, total_revenue DESC
LIMIT 50;
