WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        RANK() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
        OR s.s_acctbal IS NULL
),
CustomerStats AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01'
        AND l.l_shipdate < CURRENT_DATE
    GROUP BY 
        l.l_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(sd.s_name, 'Unknown Supplier') AS supplier_name,
    cs.order_count,
    cs.total_spent,
    la.total_revenue,
    la.unique_parts,
    CASE 
        WHEN la.total_revenue IS NULL THEN 'No Revenue'
        WHEN la.total_revenue > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    RankedParts rp
LEFT JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey 
LEFT JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey 
LEFT JOIN 
    CustomerStats cs ON cs.order_count IS NOT NULL 
LEFT JOIN 
    LineItemAnalysis la ON la.l_orderkey = (SELECT MIN(o.o_orderkey) 
                                             FROM orders o 
                                             WHERE o.o_custkey = cs.c_custkey 
                                             AND o.o_orderkey IS NOT NULL)
WHERE 
    rp.price_rank <= 3 
    AND (sd.nation_name IS NULL OR sd.nation_name LIKE '%land%')
ORDER BY 
    rp.p_partkey, 
    supplier_name DESC;
