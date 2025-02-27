WITH RECURSIVE part_hierarchy AS (
    SELECT 
        p.p_partkey AS part_key,
        p.p_name AS part_name,
        p.p_retailprice AS retail_price,
        p.p_comment AS part_comment,
        0 AS level
    FROM 
        part p
    WHERE 
        p.p_size < 20
    
    UNION ALL
    
    SELECT 
        ps.ps_partkey AS part_key,
        p.p_name AS part_name,
        p.p_retailprice AS retail_price,
        CONCAT(ph.part_comment, ' -> ', p.p_comment) AS part_comment,
        ph.level + 1
    FROM 
        part_hierarchy ph
    JOIN 
        partsupp ps ON ph.part_key = ps.ps_partkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    WHERE 
        ph.level < 3
),
supplier_status AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    SUM(cs.total_spent) AS total_customer_spend,
    AVG(ss.avg_acctbal) AS average_supplier_balance,
    COUNT(DISTINCT ph.part_key) FILTER (WHERE ph.level > 0) AS complex_parts_count
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier_status ss ON ss.total_parts > (SELECT AVG(total_parts) FROM supplier_status)
LEFT JOIN 
    customer_orders cs ON cs.c_custkey = n.n_nationkey
LEFT JOIN 
    part_hierarchy ph ON ph.part_key IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 100)
WHERE 
    n.n_comment IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    total_customer_spend DESC
LIMIT 10;
