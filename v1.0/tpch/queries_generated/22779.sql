WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal >= 10000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.n_nationkey = sh.n_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
PartStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_availqty, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
),
QualifiedCustomers AS (
    SELECT co.c_custkey, co.total_orders, co.total_spent
    FROM CustomerOrders co
    WHERE co.total_orders > 5 OR co.total_spent > 5000
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
)
SELECT nsh.n_name AS nation, ps.p_name AS part_name, rs.total_availqty, cp.total_orders,
       CASE 
           WHEN cp.total_orders IS NULL THEN 'No Orders'
           ELSE CAST(cp.total_orders AS VARCHAR) || ' Orders'
       END AS order_info,
       (SELECT COUNT(*) FROM SupplierHierarchy sh WHERE sh.level = 1) AS high_balance_suppliers,
       (SELECT MAX(ps.avg_supplycost) FROM PartStats ps WHERE ps.total_availqty > 100) AS max_avg_supplycost
FROM region r
JOIN nation nsh ON r.r_regionkey = nsh.n_regionkey
LEFT JOIN RankedParts rp ON rp.price_rank <= 5
LEFT JOIN PartStats ps ON ps.p_partkey = rp.p_partkey
LEFT JOIN QualifiedCustomers cp ON cp.c_custkey = (SELECT MIN(c.c_custkey) FROM customer c WHERE c.c_nationkey = nsh.n_nationkey)
WHERE rp.p_name IS NOT NULL
ORDER BY nation, part_name, ps.total_availqty DESC
LIMIT 10;
