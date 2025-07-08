WITH SupplierInfo AS (
    SELECT s.s_name, 
           s.s_phone,
           r.r_name AS supplier_region,
           s.s_acctbal,
           COUNT(ps.ps_supplycost) AS total_parts_supplied
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name, s.s_phone, r.r_name, s.s_acctbal
),
PartDetails AS (
    SELECT p.p_name,
           p.p_retailprice,
           LENGTH(p.p_comment) AS comment_length,
           p.p_container
    FROM part p
    WHERE p.p_retailprice > 100.00
),
OrderSummary AS (
    SELECT o.o_orderkey,
           c.c_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
           COUNT(DISTINCT l.l_partkey) AS unique_parts_ordered
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, c.c_name
)

SELECT si.s_name AS supplier_name,
       si.s_phone AS supplier_contact,
       si.supplier_region,
       si.s_acctbal,
       si.total_parts_supplied,
       pd.p_name AS part_name,
       pd.p_retailprice,
       pd.comment_length,
       pd.p_container,
       os.total_order_value,
       os.unique_parts_ordered
FROM SupplierInfo si
JOIN PartDetails pd ON si.total_parts_supplied > 5
JOIN OrderSummary os ON os.unique_parts_ordered > 10
ORDER BY si.s_acctbal DESC, os.total_order_value DESC;
