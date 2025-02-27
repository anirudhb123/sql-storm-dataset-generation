WITH ProcessedSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        UPPER(s.s_name) AS upper_name,
        CONCAT('Supplier: ', s.s_name, ' | Address: ', s.s_address) AS full_info
    FROM supplier s
),
FilteredCustomer AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_nationkey,
        c.c_phone,
        c.c_acctbal,
        c.c_mktsegment,
        LENGTH(c.c_comment) AS comment_length,
        REPLACE(c.c_comment, 'customer', 'client') AS modified_comment
    FROM customer c
    WHERE c.c_acctbal > 1000
),
AggregatedLineItems AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM lineitem l
    GROUP BY l.l_partkey
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    p.p_type,
    ps.ps_availqty,
    ps.ps_supplycost,
    s.upper_name,
    s.full_info,
    c.c_name,
    c.comment_length,
    a.total_quantity,
    a.total_revenue
FROM partsupp ps
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN ProcessedSupplier s ON ps.ps_suppkey = s.s_suppkey
JOIN FilteredCustomer c ON s.s_nationkey = c.c_nationkey
JOIN AggregatedLineItems a ON p.p_partkey = a.l_partkey
WHERE a.total_revenue > 10000
ORDER BY total_revenue DESC
LIMIT 50;
