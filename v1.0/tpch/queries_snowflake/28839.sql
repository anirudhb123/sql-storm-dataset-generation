WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand, p.p_type ORDER BY p.p_retailprice DESC) AS rank_per_brand_type
    FROM 
        part p
    WHERE
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice < 100.00)
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
OrderStatistics AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS total_line_items,
        SUM(l.l_extendedprice) AS total_extended_price,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    sd.s_name,
    sd.nation_name,
    os.total_line_items,
    os.total_extended_price,
    os.last_ship_date
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    OrderStatistics os ON os.o_orderkey = (SELECT o.o_orderkey FROM orders o 
                                            JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
                                            WHERE l.l_partkey = rp.p_partkey 
                                            ORDER BY o.o_orderkey DESC LIMIT 1)
WHERE 
    rp.rank_per_brand_type <= 5
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC;
