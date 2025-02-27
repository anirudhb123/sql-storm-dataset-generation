WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1995-01-01' AND 
        o.o_orderstatus IN ('O', 'F')
),
SuppliersWithDiscounts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        CASE 
            WHEN s.s_acctbal = 0 THEN NULL 
            ELSE (ps.ps_supplycost / s.s_acctbal) 
        END AS discount_ratio
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS part_rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20 AND 
        p.p_comment IS NOT NULL
)
SELECT 
    r.r_name,
    COUNT(DISTINCT coalesce(s.s_suppkey, -1)) AS supplier_count,
    SUM(o.o_totalprice) AS total_order_value,
    AVG(pd.p_retailprice) AS avg_part_price,
    MAX(pd.part_rank) AS max_part_rank
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SuppliersWithDiscounts sd ON s.s_suppkey = sd.ps_suppkey
LEFT JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN 
    RankedOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    PartDetails pd ON l.l_partkey = pd.p_partkey
WHERE 
    (o.o_orderstatus IS NOT NULL OR sd.discount_ratio IS NOT NULL)
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > (SELECT COUNT(*) FROM supplier) / 10
ORDER BY 
    total_order_value DESC;
