WITH part_supplier_data AS (
    SELECT 
        p.p_name,
        p.p_mfgr,
        p.p_type,
        p.p_size,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
customer_order_data AS (
    SELECT 
        c.c_name,
        c.c_nationkey,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
string_benchmarking AS (
    SELECT 
        CONCAT(p.p_name, ' - ', p.p_mfgr) AS product_info,
        SUBSTRING(ps.ps_comment FROM 1 FOR 20) AS short_comment,
        LOWER(s.s_name) AS supplier_name_lower,
        UPPER(c.c_name) AS customer_name_upper,
        LENGTH(p.p_comment) AS comment_length,
        LENGTH(c.c_comment) AS customer_comment_length
    FROM part_supplier_data ps
    JOIN customer_order_data o ON ps.s_suppkey = o.o_orderkey
    JOIN nation n ON n.n_nationkey = o.c_nationkey
)
SELECT 
    product_info,
    short_comment,
    supplier_name_lower,
    customer_name_upper,
    AVG(comment_length) AS avg_part_comment_length,
    AVG(customer_comment_length) AS avg_customer_comment_length
FROM string_benchmarking
GROUP BY product_info, short_comment, supplier_name_lower, customer_name_upper
ORDER BY avg_part_comment_length DESC, avg_customer_comment_length DESC;
