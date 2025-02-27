WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS Level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.Level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_mfgr = 'SupplierX') LIMIT 1)
    WHERE sh.Level < 3
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineItemStats AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
GroupedLineItems AS (
    SELECT l.l_orderkey, COUNT(*) AS item_count, AVG(l.l_quantity) AS avg_quantity
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.order_count,
    cs.total_spent,
    lh.item_count,
    rhs.Level AS supplier_level,
    COALESCE(ls.net_revenue, 0) AS total_revenue
FROM CustomerOrderStats cs
LEFT JOIN GroupedLineItems lh ON cs.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey LIMIT 1))
LEFT JOIN LineItemStats ls ON lh.l_orderkey = ls.l_orderkey
LEFT JOIN SupplierHierarchy rhs ON rhs.s_acctbal > cs.total_spent 
WHERE cs.total_spent > 5000
ORDER BY cs.total_spent DESC, lh.item_count ASC;
