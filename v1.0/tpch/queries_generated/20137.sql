WITH RECURSIVE SupplyChain AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, 
           SUM(ps.ps_availqty) AS total_availqty, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
    HAVING SUM(ps.ps_availqty) IS NOT NULL
),
SupplierMetrics AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           COUNT(DISTINCT ps.ps_partkey) AS num_parts,
           AVG(s.s_acctbal) AS avg_acctbal
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
    HAVING AVG(s.s_acctbal) > 0
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(DISTINCT o.o_orderkey) > 0
)
SELECT 
    n.n_name AS nation,
    SUM(CASE WHEN lm.total_availqty IS NULL THEN 0 ELSE lm.total_availqty END) AS total_available_parts,
    COUNT(DISTINCT cm.c_custkey) AS total_customers,
    SUM(cm.total_spent) AS total_spent_per_nation
FROM nation n
LEFT JOIN SupplyChain lm ON n.n_nationkey = lm.p_mfgr::integer
LEFT JOIN CustomerOrders cm ON n.n_nationkey = cm.total_orders
WHERE n.n_comment NOT ILIKE '%obsolete%'
GROUP BY n.n_name
HAVING SUM(lm.total_available_parts) > 
       (SELECT AVG(total_availqty) FROM SupplyChain) 
       AND COUNT(DISTINCT cm.c_custkey) > 10
ORDER BY total_spent_per_nation DESC NULLS LAST;
