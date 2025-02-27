WITH SupplierDetails AS (
    SELECT s.s_name, s.s_address, n.n_name AS nation_name, r.r_name AS region_name, s.s_acctbal, 
           REPLACE(UPPER(s.s_comment), 'SUPPLIER', 'PARTNER') AS modified_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
), 
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_name AS customer_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_name
)
SELECT sd.s_name, sd.nation_name, sd.region_name, COUNT(od.o_orderkey) AS total_orders, 
       AVG(sd.s_acctbal) AS average_supplier_balance, 
       STRING_AGG(DISTINCT od.customer_name, ', ') AS customer_names
FROM SupplierDetails sd
LEFT JOIN OrderDetails od ON sd.s_address LIKE '%' || od.o_orderdate || '%'
GROUP BY sd.s_name, sd.nation_name, sd.region_name
ORDER BY total_orders DESC, average_supplier_balance DESC;
