WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
      AND sh.hierarchy_level < 3
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000 
    GROUP BY c.c_custkey, c.c_name
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
RankedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, 
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS item_rank
    FROM lineitem l
    WHERE l.l_discount > 0.1 AND l.l_returnflag = 'N'
)
SELECT 
    n.n_name AS nation,
    SUM(co.total_orders) AS total_orders,
    SUM(ps.total_available) AS total_available_parts,
    AVG(s.s_acctbal) AS avg_account_balance,
    COUNT(DISTINCT rli.l_orderkey) AS total_ranked_items
FROM nation n
LEFT JOIN CustomerOrders co ON n.n_nationkey = co.c_custkey
LEFT JOIN PartSupplier ps ON ps.p_partkey IN (
    SELECT l.l_partkey 
    FROM RankedLineItems l 
    WHERE l.item_rank <= 5
)
LEFT JOIN SupplierHierarchy s ON s.s_nationkey = n.n_nationkey
LEFT JOIN RankedLineItems rli ON rli.l_partkey = ps.p_partkey
WHERE n.n_nationkey IS NOT NULL
GROUP BY n.n_name
ORDER BY total_orders DESC, avg_account_balance ASC;
