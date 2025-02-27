WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT ps.s_suppkey, s.s_name, s.n_nationkey, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
), 
NewOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_orderdate
),
RankedOrders AS (
    SELECT o.order_total, 
           RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.order_total DESC) AS order_rank,
           CASE 
               WHEN o.order_total > 10000 THEN 'High'
               WHEN o.order_total BETWEEN 5000 AND 10000 THEN 'Medium'
               ELSE 'Low'
           END AS value_segment
    FROM NewOrders o
),
SelectedOrders AS (
    SELECT r.order_total, r.order_rank, r.value_segment, c.c_name, n.n_name
    FROM RankedOrders r
    JOIN customer c ON r.value_segment = CASE 
                                            WHEN r.order_rank <= 10 THEN 'High' 
                                            ELSE 'Low' 
                                          END
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE n.n_name IS NOT NULL
)
SELECT s.s_name, 
       COALESCE(so.order_total, 0) AS total_order_value, 
       COALESCE(sh.level, -1) AS supplier_level
FROM supplier s
LEFT JOIN SelectedOrders so ON s.s_suppkey = so.c_custkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
ORDER BY supplier_level DESC, total_order_value DESC;
