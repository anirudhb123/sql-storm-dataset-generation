WITH RECURSIVE price_cte AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_supplycost,
        (p.p_retailprice - ps.ps_supplycost) AS price_diff,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY (p.p_retailprice - ps.ps_supplycost) DESC) AS rn
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_supplycost IS NOT NULL
),
excess_customers AS (
    SELECT
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.custkey
    HAVING 
        SUM(o.o_totalprice) > 10000
),
nation_info AS (
    SELECT 
        n.n_name,
        COUNT(*) AS supplier_count,
        ARRAY_AGG(DISTINCT s.s_name) AS suppliers
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey
    HAVING 
        COUNT(s.s_suppkey) > 5
)
SELECT 
    n.n_name AS nation_name,
    COALESCE(pc.p_name, 'No Price Difference') AS part_name,
    pc.price_diff,
    ec.total_spent,
    ni.supplier_count,
    ni.suppliers
FROM 
    nation_info ni
FULL OUTER JOIN price_cte pc ON ni.supplier_count = pc.rn
FULL JOIN excess_customers ec ON ec.custkey = (SELECT MIN(c.custkey) FROM customer c)
WHERE 
    pc.price_diff IS NOT NULL
    OR ni.supplier_count IS NOT NULL
ORDER BY 
    n.n_name ASC NULLS LAST;
