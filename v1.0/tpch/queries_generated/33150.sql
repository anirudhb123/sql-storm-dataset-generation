WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
    UNION ALL
    SELECT sc.s_suppkey, sc.s_name, sc.s_nationkey, 
           sc.total_cost + p.p_retailprice * SUM(ps.ps_availqty) AS total_cost
    FROM SupplyChain sc
    JOIN part p ON p.p_partkey = (SELECT ps.ps_partkey 
                                    FROM partsupp ps 
                                    WHERE ps.ps_suppkey = sc.s_suppkey
                                    ORDER BY ps.ps_supplycost DESC 
                                    LIMIT 1)
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY sc.s_suppkey, sc.s_name, sc.s_nationkey, sc.total_cost
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderstatus = 'F'
),
CustomerPurchaseSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, COUNT(DISTINCT c.c_custkey) AS customer_count, 
       AVG(cps.total_spent) AS avg_spent,
       MAX(cps.total_orders) AS max_orders,
       COALESCE(MAX(so.total_cost), 0) AS max_supplier_cost
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN CustomerPurchaseSummary cps ON c.c_custkey = cps.c_custkey
LEFT JOIN SupplyChain so ON c.c_nationkey = so.s_nationkey
WHERE r.r_comment LIKE '%important%'
GROUP BY r.r_name
ORDER BY customer_count DESC, avg_spent DESC;
