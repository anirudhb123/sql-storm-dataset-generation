WITH SupplierAggregates AS (
    SELECT ps.ps_suppkey,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT p.p_partkey) AS part_count
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey,
           COUNT(o.o_orderkey) AS order_count,
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
FilteredLineItems AS (
    SELECT l.l_orderkey,
           l.l_partkey,
           l.l_quantity,
           l.l_extendedprice,
           l.l_discount,
           (l.l_extendedprice * (1 - l.l_discount)) AS final_price
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    AND l.l_shipdate >= '2023-01-01'
),
RankedSuppliers AS (
    SELECT sa.ps_suppkey,
           sa.total_available,
           sa.avg_supply_cost,
           RANK() OVER (ORDER BY sa.total_available DESC) AS rank
    FROM SupplierAggregates sa
)
SELECT n.n_name,
       SUM(f.final_price) AS total_revenue,
       AVG(ca.avg_order_value) AS average_customer_order_value,
       COUNT(DISTINCT ls.l_orderkey) AS distinct_orders,
       MAX(rs.total_available) AS max_supplier_avail,
       CASE WHEN COUNT(DISTINCT ca.c_custkey) > 0 
            THEN SUM(f.final_price) / COUNT(DISTINCT ca.c_custkey) 
            ELSE NULL 
       END AS revenue_per_customer
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN RankedSuppliers rs ON s.s_suppkey = rs.ps_suppkey
LEFT JOIN FilteredLineItems f ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = f.l_partkey)
LEFT JOIN CustomerOrders ca ON ca.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = f.l_orderkey LIMIT 1)
WHERE n.n_name LIKE 'A%' 
GROUP BY n.n_name
ORDER BY total_revenue DESC
LIMIT 10;
