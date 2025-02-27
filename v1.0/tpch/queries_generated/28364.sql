WITH SupplierDetails AS (
    SELECT 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation_name,
        p.p_name, 
        p.p_mfgr, 
        p.p_type, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        ps.ps_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
OrderMetrics AS (
    SELECT 
        o.o_orderkey, 
        c.c_name, 
        COUNT(l.l_orderkey) AS total_line_items, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        SUM(l.l_tax) AS total_tax,
        AVG(l.l_discount) AS avg_discount
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, c.c_name
)
SELECT 
    sd.s_name, 
    sd.nation_name, 
    sd.p_name, 
    sd.p_mfgr, 
    sd.p_type, 
    om.total_line_items, 
    om.total_sales, 
    om.total_tax, 
    om.avg_discount,
    CONCAT(sd.p_comment, ' ', sd.ps_comment) AS combined_comments,
    UPPER(sd.nation_name) AS upper_nation,
    LOWER(sd.p_name) AS lower_part_name
FROM SupplierDetails sd
JOIN OrderMetrics om ON sd.ps_availqty > 100 
WHERE sd.ps_supplycost < 500.00 
ORDER BY om.total_sales DESC, sd.s_name ASC
LIMIT 50;
