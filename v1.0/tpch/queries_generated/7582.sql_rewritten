WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), OrdersWithCustomerInfo AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_orderstatus, o.o_totalprice, c.c_name, n.n_name AS nation_name
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE o.o_orderstatus = 'F'
), LineItemsWithPartInfo AS (
    SELECT li.l_orderkey, li.l_partkey, li.l_quantity, li.l_discount, li.l_extendedprice, p.p_type, p.p_brand
    FROM lineitem li
    JOIN part p ON li.l_partkey = p.p_partkey
    WHERE li.l_shipdate >= '1997-01-01'
), CombinedData AS (
    SELECT oi.o_orderkey, oi.o_orderdate, oi.o_totalprice, oi.c_name, oi.nation_name, 
           li.l_quantity, li.l_discount, li.l_extendedprice, 
           rs.s_name, rs.TotalCost
    FROM OrdersWithCustomerInfo oi
    JOIN LineItemsWithPartInfo li ON oi.o_orderkey = li.l_orderkey
    JOIN RankedSuppliers rs ON li.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rs.s_suppkey)
)
SELECT c_name, nation_name, COUNT(*) AS total_orders, SUM(o_totalprice) AS total_revenue,
       AVG(l_extendedprice) AS avg_extended_price, AVG(TotalCost) AS avg_supplier_cost
FROM CombinedData
GROUP BY c_name, nation_name
HAVING COUNT(*) > 10 
ORDER BY total_revenue DESC, c_name;