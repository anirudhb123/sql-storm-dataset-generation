WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal,
           CONCAT(s.s_name, ' ', s.s_address, ' ', (SELECT n.n_name FROM nation n WHERE n.n_nationkey = s.s_nationkey)) AS supplier_full_info
    FROM supplier s
),
PartInfo AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_size, 
           CONCAT(p.p_name, ' - ', p.p_brand, ' - ', p.p_type) AS part_full_details
    FROM part p
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_orderstatus, c.c_name,
           CONCAT(o.o_orderstatus, ' order on ', TO_CHAR(o.o_orderdate, 'YYYY-MM-DD'), ' by ', c.c_name) AS order_full_info
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
LineItemAggregation AS (
    SELECT l.l_orderkey, SUM(l.l_quantity) AS total_quantity, COUNT(*) AS line_count, 
           STRING_AGG(DISTINCT CONCAT(l.l_partkey, ' ', (SELECT p.p_name FROM part p WHERE p.p_partkey = l.l_partkey)), ', ') AS parts_contributed
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT si.supplier_full_info, pi.part_full_details, od.order_full_info, li.total_quantity, li.line_count, li.parts_contributed
FROM SupplierInfo si
JOIN partsupp ps ON si.s_suppkey = ps.ps_suppkey
JOIN PartInfo pi ON ps.ps_partkey = pi.p_partkey
JOIN OrderDetails od ON ps.ps_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = od.o_orderkey LIMIT 1)
JOIN LineItemAggregation li ON od.o_orderkey = li.l_orderkey
WHERE si.s_acctbal > 10000
ORDER BY li.total_quantity DESC, si.supplier_full_info;
