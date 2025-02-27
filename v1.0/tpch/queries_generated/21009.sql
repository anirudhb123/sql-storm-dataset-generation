WITH RECURSIVE HighValuedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) AND s.s_comment IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
    FROM supplier s
    JOIN HighValuedSuppliers h ON s.s_nationkey = h.s_nationkey
    WHERE s.s_acctbal > h.s_acctbal
), 

CustomerOrderStats AS (
    SELECT c.c_custkey, 
           COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_within_nation
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_nationkey
    HAVING total_orders > (SELECT AVG(total_orders) FROM (SELECT COUNT(o.o_orderkey) AS total_orders 
                                                               FROM orders o 
                                                               GROUP BY o.o_custkey) AS subquery)
), 

LineitemInfo AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           MAX(l.l_shipdate) AS last_ship_date,
           COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM lineitem l
    WHERE l.l_shipdate > '2022-01-01'
    GROUP BY l.l_orderkey
)

SELECT n.n_name,
       SUM(case when ps.ps_availqty IS NULL then 0 else ps.ps_availqty end) AS total_available_quantity,
       COUNT(DISTINCT ps.ps_partkey) AS distinct_parts_supplied,
       SUM(COALESCE(cos.total_spent, 0)) AS total_spent_by_customers_below_average,
       AVG(l.net_revenue) AS average_net_revenue_per_order
FROM nation n
LEFT JOIN partsupp ps ON n.n_nationkey = ps.ps_suppkey
LEFT JOIN HighValuedSuppliers hvs ON hvs.s_nationkey = n.n_nationkey
LEFT JOIN CustomerOrderStats cos ON cos.c_nationkey = n.n_nationkey
LEFT JOIN LineitemInfo l ON l.l_orderkey = cos.c_custkey 
WHERE n.n_name NOT IN ('Zambia', 'Narnia')
GROUP BY n.n_name
HAVING SUM(ps.ps_availqty) IS NOT NULL 
   AND AVG(l.net_revenue) > (SELECT AVG(net_revenue) FROM LineitemInfo)
ORDER BY total_available_quantity DESC, n.n_name ASC;
