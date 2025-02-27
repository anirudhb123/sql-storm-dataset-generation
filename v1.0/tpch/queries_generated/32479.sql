WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderstatus, o_totalprice, o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate) AS order_level
    FROM orders
    WHERE o_orderstatus = 'O'
),
CustomerRevenue AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_revenue,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierCosts AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
),
LatestLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_quantity, l.l_extendedprice,
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_shipdate DESC) AS line_rank
    FROM lineitem l
),
FinalReport AS (
    SELECT c.c_name AS customer_name, c.total_revenue, c.order_count,
           p.p_name AS part_name, sc.total_supply_cost, 
           COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS discounted_total
    FROM CustomerRevenue c
    JOIN HighValueParts p ON p.price_rank <= 10
    LEFT JOIN LatestLineItems l ON l.l_partkey = p.p_partkey
    LEFT JOIN SupplierCosts sc ON sc.s_suppkey = (SELECT ps.ps_suppkey 
                                                   FROM partsupp ps 
                                                   WHERE ps.ps_partkey = l.l_partkey
                                                   LIMIT 1)
    GROUP BY c.c_name, c.total_revenue, c.order_count, p.p_name, sc.total_supply_cost
)
SELECT fr.customer_name, fr.total_revenue, fr.order_count, fr.part_name,
       fr.total_supply_cost, fr.discounted_total,
       CASE WHEN fr.discounted_total IS NULL THEN 'No Sales' ELSE 'Sales Exists' END AS sales_status
FROM FinalReport fr
WHERE fr.total_revenue > (SELECT AVG(total_revenue) FROM CustomerRevenue)
ORDER BY fr.total_revenue DESC;
