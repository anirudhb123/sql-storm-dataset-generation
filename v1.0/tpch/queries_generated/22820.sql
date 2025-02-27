WITH CustomerOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           MAX(o.o_orderdate) AS last_order_date
      FROM customer c
      LEFT JOIN orders o ON c.c_custkey = o.o_custkey
     GROUP BY c.c_custkey, c.c_name
),
HighSpendingCustomers AS (
    SELECT c.custkey,
           c.name,
           co.total_spent,
           RANK() OVER (ORDER BY co.total_spent DESC) AS spending_rank
      FROM (SELECT DISTINCT c_custkey as custkey, c_name as name FROM customer) c
      JOIN CustomerOrders co ON c.custkey = co.c_custkey
     WHERE co.total_spent IS NOT NULL AND co.order_count > 3
),
PopularParts AS (
    SELECT p.p_partkey,
           p.p_name,
           COUNT(l.l_partkey) AS total_sales,
           AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
      FROM part p
      JOIN lineitem l ON p.p_partkey = l.l_partkey
     WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
     GROUP BY p.p_partkey, p.p_name
     HAVING COUNT(l.l_partkey) > 5
),
SupplierStatistics AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_availqty) AS total_avail,
           (SUM(ps.ps_supplycost * ps.ps_availqty) / NULLIF(SUM(ps.ps_availqty), 0)) AS avg_supply_cost
      FROM supplier s
      JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
     GROUP BY s.s_suppkey, s.s_name
),
RankedPopularParts AS (
    SELECT pp.p_partkey,
           pp.p_name,
           pp.total_sales,
           pp.avg_price,
           DENSE_RANK() OVER (ORDER BY pp.total_sales DESC) AS sales_rank
      FROM PopularParts pp
),
FinalReport AS (
    SELECT Cust.c_name,
           Cust.order_count,
           Cust.total_spent,
           Part.p_name,
           Part.total_sales,
           Part.avg_price,
           CASE 
               WHEN Cust.order_count IS NULL THEN 'No Orders'
               WHEN Cust.total_spent >= 10000 THEN 'High Value'
               ELSE 'Regular Customer'
           END AS customer_status
      FROM HighSpendingCustomers Cust
      FULL OUTER JOIN RankedPopularParts Part ON Cust.custkey = Part.p_partkey
     WHERE Cust.spending_rank < 11 OR Part.sales_rank < 6
)
SELECT *
  FROM FinalReport
 WHERE customer_status != 'No Orders'
   AND (total_spent IS NOT NULL OR total_sales >= 10)
 ORDER BY customer_status, total_spent DESC, total_sales DESC;
