WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size
),
TopParts AS (
    SELECT 
        pd.p_partkey,
        pd.p_name,
        pd.total_revenue,
        RANK() OVER (ORDER BY pd.total_revenue DESC) AS revenue_rank
    FROM 
        PartDetails pd
    WHERE 
        pd.total_revenue > 10000
)

SELECT 
    tp.p_name,
    tp.total_revenue,
    sc.s_name,
    sc.total_cost
FROM 
    TopParts tp
JOIN 
    SupplierCosts sc ON tp.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_name = sc.s_name)
    )
WHERE 
    tp.revenue_rank <= 10
ORDER BY 
    tp.total_revenue DESC, sc.total_cost ASC;
