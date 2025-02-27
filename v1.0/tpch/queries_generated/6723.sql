WITH RankedNations AS (
    SELECT 
        n_name,
        n_regionkey,
        ROW_NUMBER() OVER (PARTITION BY n_regionkey ORDER BY COUNT(DISTINCT s_suppkey) DESC) AS nation_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name, n.n_regionkey
),
TopRegions AS (
    SELECT 
        r.r_name,
        SUM(p.p_retailprice * ps.ps_availqty) AS total_value
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        n.nation_rank = 1
    GROUP BY 
        r.r_name
)
SELECT 
    tr.r_name,
    tr.total_value,
    SUM(o.o_totalprice) AS total_order_value,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(c.c_acctbal) AS avg_account_balance
FROM 
    TopRegions tr
LEFT JOIN 
    customer c ON c.c_nationkey = (
        SELECT 
            n.n_nationkey 
        FROM 
            nation n 
        JOIN 
            region r ON n.n_regionkey = r.r_regionkey 
        WHERE 
            r.r_name = tr.r_name
    )
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
GROUP BY 
    tr.r_name, tr.total_value
ORDER BY 
    total_value DESC, total_order_value DESC;
