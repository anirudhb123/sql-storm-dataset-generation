WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000.00
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01'
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           p.p_retailprice, 
           CASE 
               WHEN ps.ps_supplycost IS NULL THEN 'N/A'
               ELSE CAST((ps.ps_supplycost / p.p_retailprice) * 100 AS varchar(10)) || '%'
           END AS cost_percentage
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
AggregatedLineItem AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY l.l_orderkey
)

SELECT DISTINCT
    r.r_name,
    n.n_name,
    sh.s_name,
    SUM(alo.net_revenue) AS total_net_revenue,
    SUM(ps.ps_availqty) AS total_available_qty,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    AVG(co.o_totalprice) AS avg_order_value,
    MAX(sh.level) AS max_supplier_level
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN CustomerOrders co ON n.n_nationkey = co.c_custkey
LEFT JOIN AggregatedLineItem alo ON co.o_orderkey = alo.l_orderkey
LEFT JOIN PartSupplierInfo ps ON ps.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = co.o_orderkey)
WHERE sh.level IS NOT NULL OR co.o_orderkey IS NULL
GROUP BY r.r_name, n.n_name, sh.s_name
ORDER BY total_net_revenue DESC, avg_order_value DESC;
