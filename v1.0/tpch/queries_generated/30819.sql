WITH RECURSIVE TopSuppliers AS (
    SELECT s_suppkey, s_name, SUM(ps_supplycost * ps_availqty) AS total_supply_value
    FROM supplier
    JOIN partsupp ON s_suppkey = ps_suppkey
    GROUP BY s_suppkey, s_name
    HAVING SUM(ps_supplycost * ps_availqty) > 10000
), 
RankedCustomers AS (
    SELECT c_custkey, c_name, 
           RANK() OVER (PARTITION BY c_nationkey ORDER BY c_acctbal DESC) AS rank_within_nation
    FROM customer
), 
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount,
           CASE 
               WHEN l.l_discount > 0.1 THEN 'High Discount'
               WHEN l.l_discount BETWEEN 0.05 AND 0.1 THEN 'Medium Discount'
               ELSE 'No Discount'
           END AS discount_category
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate > '2023-01-01'
)
SELECT DISTINCT 
       r.r_name AS region_name,
       n.n_name AS nation_name,
       tc.cust_name,
       oh.o_orderdate,
       SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_sales,
       p.p_name,
       ts.total_supply_value
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN RankedCustomers rc ON n.n_nationkey = rc.c_nationkey
JOIN customer tc ON rc.c_custkey = tc.c_custkey
JOIN OrderDetails od ON od.o_orderkey = tc.c_custkey
JOIN part p ON p.p_partkey = od.l_partkey
LEFT JOIN TopSuppliers ts ON p.p_partkey = ts.s_suppkey
WHERE ts.total_supply_value IS NOT NULL OR od.discount_category = 'High Discount'
GROUP BY r.r_name, n.n_name, tc.c_name, oh.o_orderdate, p.p_name, ts.total_supply_value
HAVING SUM(od.l_extendedprice * (1 - od.l_discount)) > 1000
ORDER BY total_sales DESC;
