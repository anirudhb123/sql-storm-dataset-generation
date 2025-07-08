
WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, n.n_name AS nation_name,
           SUBSTRING(s.s_address, 1, 20) AS short_address,
           s.s_acctbal,
           LENGTH(s.s_comment) AS comment_length
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartSupplierInfo AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_supplycost, p.p_name,
           CONCAT(p.p_name, ' (', s.s_name, ')') AS part_supplier_desc
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN SupplierInfo s ON ps.ps_suppkey = s.s_suppkey
),
OrderLineItemInfo AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice,
           o.o_orderstatus, o.o_orderpriority, l.l_shipmode,
           CONCAT(o.o_orderstatus, '-', o.o_orderpriority) AS order_status_priority
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
)
SELECT si.nation_name, COUNT(DISTINCT si.s_suppkey) AS unique_suppliers,
       SUM(ps.ps_supplycost) AS total_supply_cost,
       SUM(oli.l_quantity) AS total_quantity,
       AVG(oli.l_extendedprice) AS avg_extended_price,
       MAX(si.comment_length) AS max_comment_length,
       LISTAGG(DISTINCT ps.part_supplier_desc, ', ') AS part_supplier_descriptions
FROM SupplierInfo si
JOIN PartSupplierInfo ps ON si.s_suppkey = ps.ps_suppkey
JOIN OrderLineItemInfo oli ON ps.ps_partkey = oli.l_partkey
GROUP BY si.nation_name
ORDER BY unique_suppliers DESC, total_quantity DESC;
