WITH SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_address, 
           n.n_name AS nation_name,
           CONCAT('Supplier ', s.s_name, ' from ', s.s_address, ', ', n.n_name) AS supplier_info
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), 
HighValueParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_retailprice, 
           ps.ps_availqty, 
           ps.ps_supplycost,
           CONCAT(p.p_name, ': Available Quantity = ', ps.ps_availqty, ', Retail Price = $', p.p_retailprice) AS part_info
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 100.00
), 
OrderDetails AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           c.c_name AS customer_name, 
           CONCAT('Order on ', o.o_orderdate, ' for ', c.c_name, ' totaling $', o.o_totalprice) AS order_info
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
), 
DetailedReports AS (
    SELECT sd.s_name, 
           hp.part_info, 
           od.order_info
    FROM SupplierDetails sd
    JOIN HighValueParts hp ON sd.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = hp.p_partkey LIMIT 1)
    JOIN OrderDetails od ON od.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = hp.p_partkey)
)
SELECT d.s_name, 
       d.part_info, 
       d.order_info 
FROM DetailedReports d
ORDER BY d.s_name, d.part_info;
