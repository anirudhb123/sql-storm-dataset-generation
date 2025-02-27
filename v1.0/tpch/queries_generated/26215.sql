WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, n.n_name AS nation_name, s.s_acctbal, 
           CONCAT(s.s_name, ' (', s.s_address, ')') AS full_info
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, 
           CONCAT(p.p_name, ' [', p.p_mfgr, ']') AS product_info
    FROM part p
), OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_name, o.o_totalprice, 
           CONCAT(c.c_name, ' - ', o.o_orderdate) AS order_info
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
), LineItemDetails AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_quantity, l.l_extendedprice, 
           CONCAT('LineItem ', l.l_linenumber, ': ', l.l_quantity, ' @ ', l.l_extendedprice) AS line_info
    FROM lineitem l
)
SELECT sd.full_info AS supplier_info, pd.product_info AS part_info, 
       od.order_info AS order_summary, lid.line_info AS line_item_summary
FROM SupplierDetails sd
JOIN PartDetails pd ON pd.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_suppkey = sd.s_suppkey
)
JOIN LineItemDetails lid ON lid.l_partkey = pd.p_partkey
JOIN OrderDetails od ON od.o_orderkey = lid.l_orderkey
ORDER BY sd.s_suppkey, od.o_orderdate DESC
LIMIT 100;
