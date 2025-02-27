WITH RECURSIVE sales_ranking AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
), part_details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_cost,
        MAX(CASE WHEN p.p_size IS NULL THEN 'UNKNOWN' ELSE p.p_size::VARCHAR END) AS size_description
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), nation_summary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    sr.c_name,
    sr.total_spent,
    pd.p_name,
    pd.total_available,
    pd.avg_cost,
    ns.n_name,
    ns.supplier_count
FROM 
    sales_ranking sr
JOIN 
    lineitem li ON sr.c_custkey = li.l_orderkey
JOIN 
    part_details pd ON li.l_partkey = pd.p_partkey
JOIN 
    nation_summary ns ON sr.c_nationkey = ns.n_nationkey
WHERE 
    sr.rank <= 5 
    AND pd.avg_cost IS NOT NULL 
    AND sr.total_spent > (
        SELECT 
            AVG(total_spent) 
        FROM 
            sales_ranking
    )
ORDER BY 
    sr.total_spent DESC, pd.avg_cost ASC
LIMIT 10;
