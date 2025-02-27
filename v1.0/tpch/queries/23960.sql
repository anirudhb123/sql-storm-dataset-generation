WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > (
        SELECT AVG(s_acctbal) 
        FROM supplier 
        WHERE s_acctbal IS NOT NULL
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5 AND s.s_acctbal > sh.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey 
    WHERE o.o_orderstatus IN ('O', 'F', 'P')
    GROUP BY c.c_custkey, c.c_name
),
LineitemStatistics AS (
    SELECT l.l_partkey, 
           SUM(l.l_quantity) AS total_quantity, 
           AVG(l.l_extendedprice) AS avg_price, 
           SUM(l.l_discount * l.l_extendedprice) AS total_discount
    FROM lineitem l
    WHERE l_shipdate BETWEEN cast('1998-10-01' as date) - INTERVAL '1 year' AND cast('1998-10-01' as date)
    GROUP BY l.l_partkey
),
TopNParts AS (
    SELECT p.*, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY l.total_quantity DESC) AS rn
    FROM part p
    JOIN LineitemStatistics l ON p.p_partkey = l.l_partkey
    WHERE p.p_size IS NOT NULL AND p.p_retailprice > 100
)
SELECT 
    r.r_name AS region,
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returns_count,
    SUM(l.l_quantity) AS total_lineitem_quantity,
    (SELECT SUM(ps.ps_supplycost * ps.ps_availqty)
     FROM partsupp ps 
     WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM TopNParts p WHERE p.rn <= 5)) AS total_supply_cost,
     SUM(s.s_acctbal) AS total_supplier_acct_balance
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN CustomerOrders c ON c.c_custkey = s.s_suppkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
WHERE r.r_name LIKE 'Eu%' 
GROUP BY r.r_name, c.c_name, s.s_name
HAVING SUM(l.l_quantity) IS NOT NULL OR SUM(s.s_acctbal) < 10000
ORDER BY region, customer_name DESC, total_orders DESC;