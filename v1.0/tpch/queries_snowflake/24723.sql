
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_within_brand
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
), SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        MAX(ps.ps_supplycost) AS max_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
), TotalSpend AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_custkey
), CustomerNation AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
), SuppliersByNation AS (
    SELECT 
        cn.nation_name,
        COUNT(DISTINCT si.s_suppkey) AS supplier_count
    FROM 
        CustomerNation cn
    JOIN 
        SupplierInfo si ON cn.c_custkey IN (
            SELECT c.c_custkey 
            FROM customer c 
            WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = cn.nation_name)
        )
    GROUP BY 
        cn.nation_name
)
SELECT 
    COALESCE(rp.p_brand, 'Unknown') AS part_brand,
    SUM(rp.p_retailprice) AS total_retail_price,
    COUNT(DISTINCT ts.o_custkey) AS customer_count,
    si.max_supply_cost,
    sbn.supplier_count,
    COALESCE(AVG(ts.total_spent), 0) AS average_spent
FROM 
    RankedParts rp
LEFT JOIN 
    TotalSpend ts ON ts.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (1, 2))
LEFT JOIN 
    SupplierInfo si ON si.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = rp.p_partkey
    )
LEFT JOIN 
    SuppliersByNation sbn ON sbn.nation_name = (
        SELECT n.n_name 
        FROM nation n 
        WHERE n.n_nationkey = (
            SELECT c.c_nationkey 
            FROM customer c 
            WHERE c.c_custkey = ts.o_custkey
        )
    )
WHERE 
    rp.rank_within_brand <= 5
GROUP BY 
    rp.p_partkey, rp.p_name, rp.p_brand, rp.p_retailprice, si.max_supply_cost, sbn.supplier_count
HAVING 
    COUNT(DISTINCT ts.o_custkey) > 10 
ORDER BY 
    total_retail_price DESC, part_brand;
