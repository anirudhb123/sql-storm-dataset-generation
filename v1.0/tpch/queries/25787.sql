WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartsInfo AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_retailprice, p.p_comment
    FROM part p
    WHERE p.p_size > 10
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 500
),
LineItemDetails AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_discount, l.l_extendedprice
    FROM lineitem l
    WHERE l.l_returnflag = 'N' AND l.l_linestatus = 'F'
)
SELECT 
    si.s_name AS supplier_name,
    pi.p_name AS part_name,
    fo.o_orderkey AS order_key,
    SUM(lid.l_extendedprice * (1 - lid.l_discount)) AS sales_amount,
    COUNT(DISTINCT fo.o_orderkey) AS total_orders,
    MAX(fo.o_orderdate) AS latest_order_date,
    si.nation_name AS nation
FROM SupplierInfo si
JOIN PartsInfo pi ON si.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey = pi.p_partkey
)
JOIN LineItemDetails lid ON lid.l_partkey = pi.p_partkey
JOIN FilteredOrders fo ON lid.l_orderkey = fo.o_orderkey
GROUP BY si.s_name, pi.p_name, fo.o_orderkey, si.nation_name
HAVING SUM(lid.l_extendedprice * (1 - lid.l_discount)) > 2000
ORDER BY sales_amount DESC, supplier_name;
