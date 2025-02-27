WITH processed_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT(SUBSTRING(p.p_name, 1, 10), '...') AS short_name,
        p.p_size,
        CASE 
            WHEN LENGTH(p.p_comment) > 50 THEN CONCAT(SUBSTRING(p.p_comment, 1, 50), '...') 
            ELSE p.p_comment 
        END AS trimmed_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank_within_type
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
),
suppliers_with_comments AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        (CASE 
            WHEN LENGTH(s.s_comment) > 100 THEN CONCAT(SUBSTRING(s.s_comment, 1, 100), '...') 
            ELSE s.s_comment 
        END) AS filtered_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 500.00
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    r.r_name AS region,
    np.n_name AS nation,
    pp.short_name,
    pp.trimmed_comment,
    sp.s_name AS supplier_name,
    sp.filtered_comment AS supplier_comment,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent
FROM 
    region r
JOIN 
    nation np ON r.r_regionkey = np.n_regionkey
JOIN 
    processed_parts pp ON pp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps JOIN supplier s ON ps.ps_suppkey = s.s_suppkey WHERE s.s_nationkey = np.n_nationkey)
JOIN 
    suppliers_with_comments sp ON sp.s_nationkey = np.n_nationkey
JOIN 
    customer_orders co ON co.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderstatus = 'O')
WHERE 
    pp.rank_within_type <= 5
ORDER BY 
    region, nation, pp.p_partkey;
