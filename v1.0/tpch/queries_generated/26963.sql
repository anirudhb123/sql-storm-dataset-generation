WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_phone, 
        s.s_acctbal, 
        REPLACE(REPLACE(s.s_comment, 'a', '@'), 'e', '3') AS obfuscated_comment
    FROM supplier s
), 
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        CONCAT(p.p_name, ' - ', p.p_brand) AS part_full_name,
        CASE 
            WHEN p.p_retailprice > 1000 THEN 'High Value'
            WHEN p.p_retailprice BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value' 
        END AS price_category
    FROM part p
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderstatus,
        DATE_PART('year', o.o_orderdate) AS order_year,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus, o.o_orderdate
)
SELECT 
    p.part_full_name, 
    s.s_name, 
    c.c_name, 
    co.total_spent, 
    co.order_year,
    COUNT(DISTINCT co.o_orderkey) AS order_count, 
    STRING_AGG(DISTINCT ps.ps_comment, '; ') AS supplier_comments
FROM PartDetails p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN SupplierDetails s ON ps.ps_suppkey = s.s_suppkey
JOIN CustomerOrders co ON s.s_suppkey = co.o_orderkey
WHERE p.price_category = 'High Value' 
GROUP BY p.part_full_name, s.s_name, c.c_name, co.order_year
ORDER BY total_spent DESC;
