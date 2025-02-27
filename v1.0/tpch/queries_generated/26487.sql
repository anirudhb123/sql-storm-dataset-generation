WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, n.n_name AS nation_name, r.r_name AS region_name,
           COUNT(DISTINCT ps.ps_partkey) AS total_parts, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_address, n.n_name, r.r_name
),
OrderDetails AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
),
CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_address, o.total_orders, o.total_spent
    FROM customer c
    LEFT JOIN OrderDetails o ON c.c_custkey = o.o_custkey
)
SELECT sd.s_suppkey, sd.s_name, sd.nation_name, sd.region_name, 
       cd.c_name AS customer_name, cd.total_orders, cd.total_spent, 
       sd.total_parts, sd.total_cost, 
       CONCAT(cd.c_name, ' from ', cd.c_address) AS customer_info, 
       CONCAT(sd.s_name, ' supplies ', sd.total_parts, ' parts in total') AS supplier_info
FROM SupplierDetails sd
JOIN CustomerDetails cd ON cd.total_orders > 0
WHERE sd.total_cost > (SELECT AVG(total_cost) FROM SupplierDetails)
ORDER BY sd.s_suppkey, cd.total_spent DESC;
