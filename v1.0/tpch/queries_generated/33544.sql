WITH RECURSIVE HighValueOrders AS (
    SELECT o_orderkey, o_totalprice
    FROM orders
    WHERE o_totalprice > 10000
  UNION ALL
    SELECT o.orderkey, o.totalprice
    FROM orders o
    INNER JOIN HighValueOrders hvo ON o.o_orderkey = hvo.o_orderkey
    WHERE o_totalprice < hvo.o_totalprice * 1.10
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 0
    GROUP BY c.c_custkey, c.c_name
),
OrderLinePlan AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM lineitem l
    WHERE l.l_returnflag = 'N' AND l.l_linestatus = 'O'
    GROUP BY l.l_orderkey
)

SELECT r.r_name, 
       COALESCE(SUM(ol.total_line_value), 0) AS total_revenue,
       s.s_name AS supplier_name,
       sd.total_supply_cost AS supplier_total_cost,
       c.c_name AS customer_name,
       co.total_spent
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN SupplierDetails sd ON sd.s_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON l.l_suppkey = s.s_suppkey
LEFT JOIN orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN CustomerOrderSummary co ON co.c_custkey = o.o_custkey
LEFT JOIN OrderLinePlan ol ON ol.l_orderkey = o.o_orderkey
WHERE sd.total_supply_cost >= 50000 AND co.order_count > 5
GROUP BY r.r_name, s.s_name, sd.total_supply_cost, c.c_name, co.total_spent
ORDER BY total_revenue DESC, r.r_name
LIMIT 10;
