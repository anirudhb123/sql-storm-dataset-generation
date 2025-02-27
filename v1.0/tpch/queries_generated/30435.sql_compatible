
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
RevenuePerCustomer AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_revenue
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, p.p_retailprice, 
           (p.p_retailprice - ps.ps_supplycost) AS profit_margin
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_container IN ('SM BOX', 'MED BOX')
),
RankedLineitems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, 
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rank
    FROM lineitem l
    WHERE l.l_tax IS NOT NULL AND l.l_discount > 0.1
)
SELECT 
    r.r_name,
    sh.s_name,
    SUM(pl.profit_margin) AS total_profit_margin,
    COUNT(DISTINCT rc.c_custkey) AS num_customers,
    AVG(rc.total_revenue) AS avg_revenue_per_customer
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN PartSupplierDetails pl ON sh.s_suppkey = pl.p_partkey
LEFT JOIN RevenuePerCustomer rc ON sh.s_nationkey = rc.c_custkey
LEFT JOIN RankedLineitems rl ON rl.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = rc.c_custkey)
GROUP BY r.r_name, sh.s_name
HAVING SUM(pl.profit_margin) > 5000
ORDER BY total_profit_margin DESC
LIMIT 10;
