WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size IS NOT NULL
), SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(s.s_acctbal) AS avg_acctbal,
        COUNT(ps.ps_partkey) AS total_parts,
        MAX(ps.ps_supplycost) AS max_supplycost,
        SUM(CASE WHEN COALESCE(s.s_comment, '') = '' THEN 1 ELSE 0 END) AS empty_comments
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), OrdersWithLineItems AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS adjusted_total,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice
), FinalReport AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        SUM(os.adjusted_total) AS total_adjusted_sales,
        AVG(ss.avg_acctbal) AS avg_supplier_acctbal
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        OrdersWithLineItems os ON c.c_custkey = os.o_orderkey
    LEFT JOIN 
        SupplierStats ss ON ss.total_parts > 5
    WHERE 
        EXISTS (
            SELECT 1
            FROM RankedParts rp
            WHERE rp.p_partkey IN (
                SELECT ps.ps_partkey
                FROM partsupp ps
                WHERE ps.ps_supplycost > (
                    SELECT MIN(ps2.ps_supplycost)
                    FROM partsupp ps2
                    WHERE ps2.ps_partkey = rp.p_partkey
                )
            ) AND rp.rn = 1
        )
    GROUP BY 
        r.r_name
)
SELECT 
    fr.region_name,
    fr.total_customers,
    fr.total_adjusted_sales,
    fr.avg_supplier_acctbal
FROM 
    FinalReport fr
WHERE 
    fr.total_adjusted_sales IS NOT NULL 
    AND fr.total_customers > (
        SELECT COUNT(DISTINCT c.c_custkey) / 2
        FROM customer c
    )
ORDER BY 
    fr.total_adjusted_sales DESC
LIMIT 10;
