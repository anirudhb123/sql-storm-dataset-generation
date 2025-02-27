WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, p_container, p_retailprice, p_comment, 0 AS level
    FROM part
    WHERE p_size = (SELECT MAX(p_size) FROM part)

    UNION ALL

    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment, ph.level + 1
    FROM part p
    INNER JOIN PartHierarchy ph ON ph.p_partkey = p.p_partkey
    WHERE ph.level < 3
),
SupplierStats AS (
    SELECT s_nationkey, COUNT(DISTINCT s_suppkey) AS supplier_count, SUM(s_acctbal) AS total_acctbal
    FROM supplier
    GROUP BY s_nationkey
),
OrderSummary AS (
    SELECT o_custkey, COUNT(o_orderkey) AS order_count, SUM(o_totalprice) AS total_spent
    FROM orders
    WHERE o_orderstatus = 'O'
    GROUP BY o_custkey
),
LineItemStats AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS net_revenue
    FROM lineitem
    GROUP BY l_orderkey
),
CustomerRanked AS (
    SELECT c.c_custkey, c.c_name, os.order_count, os.total_spent,
           ROW_NUMBER() OVER (ORDER BY os.total_spent DESC) AS rank
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_custkey
)
SELECT ph.p_name, ph.p_retailprice, sr.supplier_count, sr.total_acctbal, cr.c_name, cr.order_count, cr.total_spent, cr.rank,
       COALESCE(ROUND(SUM(l.net_revenue), 2), 0) AS total_net_revenue
FROM PartHierarchy ph
LEFT JOIN partsupp ps ON ps.ps_partkey = ph.p_partkey
LEFT JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN SupplierStats sr ON sr.s_nationkey = s.s_nationkey
LEFT JOIN LineItemStats l ON l.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey IN (SELECT c_custkey FROM CustomerRanked cr WHERE cr.rank <= 10))
JOIN CustomerRanked cr ON cr.c_custkey = (SELECT TOP 1 c_custkey FROM customers ORDER BY c_name DESC)
WHERE ph.level = 0
GROUP BY ph.p_name, ph.p_retailprice, sr.supplier_count, sr.total_acctbal, cr.c_name, cr.order_count, cr.total_spent, cr.rank
ORDER BY total_net_revenue DESC;
