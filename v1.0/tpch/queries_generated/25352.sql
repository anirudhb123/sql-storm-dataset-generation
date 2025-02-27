WITH region_suppliers AS (
    SELECT r_name, s_name, s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY r_name ORDER BY s_acctbal DESC) as rn
    FROM region 
    JOIN nation ON region.r_regionkey = nation.n_regionkey
    JOIN supplier ON nation.n_nationkey = supplier.s_nationkey
),
top_suppliers AS (
    SELECT r_name, s_name, s_acctbal
    FROM region_suppliers
    WHERE rn <= 3
),
product_info AS (
    SELECT p_name, p_type, p_retailprice, 
           substring(p_comment from '([^-]*)') as comment_excerpt
    FROM part 
    WHERE p_retailprice > (SELECT AVG(p_retailprice) FROM part)
)
SELECT ts.r_name, ts.s_name, pi.p_name, pi.p_type, pi.p_retailprice, pi.comment_excerpt
FROM top_suppliers ts
JOIN partsupp ps ON ps.ps_suppkey = (SELECT s_suppkey FROM supplier WHERE s_name = ts.s_name)
JOIN product_info pi ON pi.p_partkey = ps.ps_partkey
WHERE ts.s_acctbal > 50000
ORDER BY ts.r_name, ts.s_name, pi.p_retailprice DESC;
