WITH RankedOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
SupplierPartAggregates AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_availqty, 
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
SupplierNation AS (
    SELECT s.s_suppkey, 
           s.s_nationkey,
           n.n_name,
           SUM(s.s_acctbal) AS total_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_nationkey, n.n_name
),
CustomerOrderDetails AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT COALESCE(s.n_name, 'Unknown') AS supplier_nation, 
       p.p_name, 
       p.p_retailprice, 
       COALESCE(su.total_availqty, 0) AS total_availqty, 
       COALESCE(sa.avg_supplycost, 0) AS avg_supplycost, 
       SUM(CASE WHEN lo.l_returnflag = 'R' THEN lo.l_extendedprice * (1 - lo.l_discount) ELSE 0 END) AS returned_sales,
       COUNT(DISTINCT co.c_custkey) AS unique_customers
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN SupplierPartAggregates su ON p.p_partkey = su.ps_partkey
LEFT JOIN lineitem lo ON p.p_partkey = lo.l_partkey
LEFT JOIN CustomerOrderDetails co ON lo.l_orderkey IN (SELECT o.o_orderkey FROM RankedOrders o WHERE o.price_rank <= 10)
GROUP BY s.n_name, p.p_name, p.p_retailprice
ORDER BY returned_sales DESC, unique_customers DESC
LIMIT 100;
