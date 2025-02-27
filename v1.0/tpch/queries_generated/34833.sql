WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
      AND sh.level < 3
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY o.o_orderkey
),
PartSupplierRevenue AS (
    SELECT p.p_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
RankedOrders AS (
    SELECT os.o_orderkey, os.total_revenue,
           RANK() OVER (ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM OrderSummary os
),
CustomerNation AS (
    SELECT c.c_custkey, c.c_name, n.n_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE n.n_name IS NOT NULL
)
SELECT cn.c_name, R.order_key, R.total_revenue, 
       COALESCE(sp.s_name, 'Unknown Supplier') AS supplier_name,
       p.p_name, 
       (pr.total_cost - R.total_revenue) AS profit,
       CASE 
           WHEN (pr.total_cost - R.total_revenue) > 0 THEN 'Loss'
           ELSE 'Profit'
       END AS profit_status
FROM RankedOrders R
LEFT JOIN PartSupplierRevenue pr ON R.o_orderkey = pr.p_partkey
LEFT JOIN SupplierHierarchy sh ON pr.p_partkey = sh.s_suppkey
LEFT JOIN CustomerNation cn ON R.o_orderkey = cn.c_custkey
WHERE R.revenue_rank <= 10
ORDER BY profit DESC, R.total_revenue DESC;
