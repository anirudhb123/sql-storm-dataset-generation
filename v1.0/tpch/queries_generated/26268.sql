WITH SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        CONCAT(s.s_name, ' from ', s.s_address) AS supplier_info,
        LEFT(s.s_comment, 50) AS short_comment
    FROM
        supplier s
),
CustomerDetails AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_nationkey,
        CONCAT(c.c_name, ' located at ', c.c_address) AS customer_info,
        c.c_mktsegment
    FROM
        customer c
),
PartInfo AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        CASE 
            WHEN p.p_size < 10 THEN 'Small'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
            ELSE 'Large'
        END AS size_category,
        p.p_comment
    FROM
        part p
)
SELECT
    s.s_suppkey,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    p.p_name AS part_name,
    CONCAT(s.s_name, ' & ', c.c_name, ' ordered ', p.p_name) AS transaction_description,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    s.short_comment,
    c.c_mktsegment,
    p.size_category
FROM
    SupplierDetails s
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN lineitem l ON ps.ps_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN CustomerDetails c ON o.o_custkey = c.c_custkey
JOIN PartInfo p ON ps.ps_partkey = p.p_partkey
WHERE
    p.p_retailprice > 50.00
GROUP BY
    s.s_suppkey, s.s_name, c.c_name, p.p_name, s.short_comment, c.c_mktsegment, p.size_category
ORDER BY
    total_quantity DESC, avg_extended_price DESC;
