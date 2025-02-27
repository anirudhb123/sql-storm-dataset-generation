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
        p.p_size BETWEEN 1 AND 20 AND 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_container IS NOT NULL)
),

SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        r.r_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > (SELECT COALESCE(AVG(s2.s_acctbal), 0) FROM supplier s2 WHERE s2.s_comment IS NULL)
),

HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderpriority,
        COUNT(DISTINCT li.l_linenumber) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderstatus IN ('F', 'O')
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderstatus, o.o_orderpriority
    HAVING 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate >= DATEADD(MONTH, -3, CURRENT_DATE) AND o2.o_orderstatus = 'F')
),

FinalOutput AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        sd.s_name,
        sd.r_name,
        hvo.o_orderkey,
        hvo.item_count,
        COALESCE(SUM(li.l_extendedprice), 0) AS total_extended_price
    FROM 
        RankedParts rp
    LEFT JOIN 
        SupplierDetails sd ON (rp.p_brand = SUBSTRING(sd.s_name, 1, 3) OR sd.s_comment LIKE '%premium%')
    LEFT JOIN 
        lineitem li ON li.l_partkey = rp.p_partkey
    LEFT JOIN 
        HighValueOrders hvo ON li.l_orderkey = hvo.o_orderkey
    GROUP BY 
        rp.p_partkey, rp.p_name, sd.s_name, sd.r_name, hvo.o_orderkey, hvo.item_count
)

SELECT 
    DISTINCT f.p_partkey,
    f.p_name,
    f.s_name,
    f.r_name,
    f.o_orderkey,
    f.item_count,
    CASE 
        WHEN f.total_extended_price IS NULL THEN 'No Sales' 
        ELSE CAST(f.total_extended_price AS VARCHAR)
    END AS sale_status
FROM 
    FinalOutput f
ORDER BY 
    f.p_partkey, f.o_orderkey DESC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM FinalOutput) / 7;
