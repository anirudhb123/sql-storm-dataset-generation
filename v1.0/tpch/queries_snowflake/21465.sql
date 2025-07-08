
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
RecentOrders AS (
    SELECT o.o_orderkey, 
           o.o_custkey, 
           o.o_totalprice, 
           COUNT(l.l_orderkey) AS line_count,
           MAX(l.l_shipdate) AS last_shipdate,
           CASE 
               WHEN o.o_orderstatus = 'F' THEN 'Completed'
               WHEN o.o_orderstatus = 'O' THEN 'Open'
               ELSE 'Unknown' 
           END AS order_status
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1998-10-01' - INTERVAL '1 year'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderstatus
),
FilteredCustomers AS (
    SELECT c.c_custkey, 
           c.c_name, 
           c.c_acctbal, 
           c.c_mktsegment, 
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS cust_rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
)
SELECT r.r_name, 
       COALESCE(SUM(rs.total_cost), 0) AS total_supplier_cost, 
       COUNT(DISTINCT ro.o_orderkey) AS total_orders,
       AVG(fc.c_acctbal) AS avg_account_balance,
       LISTAGG(DISTINCT CONCAT(fc.c_name, ' (', fc.c_mktsegment, ')'), ', ') AS customer_info
FROM region r
LEFT JOIN RankedSuppliers rs ON r.r_regionkey = rs.s_suppkey
LEFT JOIN RecentOrders ro ON ro.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE r.r_regionkey = n.n_regionkey))
LEFT JOIN FilteredCustomers fc ON fc.c_mktsegment IN ('AUTOMOBILE', 'HOUSEHOLD') AND fc.cust_rank <= 5
WHERE r.r_name NOT LIKE '%East%'
GROUP BY r.r_name
HAVING SUM(rs.total_cost) > (SELECT AVG(ps.ps_supplycost) FROM partsupp ps) OR MAX(ro.last_shipdate) < DATE '1998-10-01' - INTERVAL '30 days'
ORDER BY total_supplier_cost DESC;
