
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address,
        s.s_phone,
        SUBSTRING(s.s_comment FROM POSITION('|' IN s.s_comment) + 1 FOR 50) AS short_comment,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length
    FROM part p
    WHERE p.p_retailprice > 100.00 AND 
          p.p_type LIKE '%green%' 
),
SupplierPartCount AS (
    SELECT 
        ps.ps_partkey, 
        COUNT(ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    r.r_name, 
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    MAX(fp.comment_length) AS max_comment_length,
    STRING_AGG(DISTINCT rs.s_name || ' (' || rs.short_comment || ')', '; ') AS supplier_details
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN RankedSuppliers rs ON rs.s_suppkey = l.l_suppkey
JOIN FilteredParts fp ON fp.p_partkey = l.l_partkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE o.o_orderstatus = 'F'
GROUP BY r.r_name
HAVING SUM(l.l_quantity) > 1000
ORDER BY total_quantity DESC;
