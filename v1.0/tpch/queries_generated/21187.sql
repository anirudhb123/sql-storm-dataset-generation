WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_size, 
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 30
        AND p.p_retailprice IS NOT NULL
),
NationalAverage AS (
    SELECT 
        n.n_nationkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_nationkey
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > (
            SELECT 
                AVG(total_price) FROM (
                    SELECT 
                        SUM(l_extendedprice * (1 - l_discount)) AS total_price
                    FROM 
                        lineitem
                    GROUP BY 
                        l_orderkey
                ) AS avg_prices
        )
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        supplied_parts > 5
)
SELECT 
    p.p_partkey,
    p.p_name,
    np.n_name,
    ss.supplied_parts,
    ss.total_avail_qty,
    RANK() OVER (PARTITION BY np.n_nationkey ORDER BY p.p_retailprice DESC) AS part_rank
FROM 
    RankedParts p
JOIN 
    NationalAverage na ON p.p_retailprice > na.avg_supplycost
JOIN 
    nation np ON na.n_nationkey = np.n_nationkey
JOIN 
    SupplierStats ss ON ss.s_suppkey IN (
        SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey
    )
LEFT JOIN 
    orders o ON o.o_custkey IN (
        SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = np.n_nationkey
    )
WHERE 
    o.o_orderstatus IS NULL
    OR o.o_orderdate IS NOT NULL
ORDER BY 
    part_rank, p.p_partkey DESC;
