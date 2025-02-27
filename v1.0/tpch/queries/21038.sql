WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
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
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rn_supplier
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 1000
),
PotentiallyNullSuppliers AS (
    SELECT 
        pd.p_partkey,
        COALESCE(SD.s_suppkey, -1) AS s_suppkey,  
        pd.p_retailprice
    FROM 
        RankedParts pd
    LEFT JOIN 
        partsupp ps ON pd.p_partkey = ps.ps_partkey
    LEFT JOIN 
        SupplierDetails SD ON ps.ps_suppkey = SD.s_suppkey
),
FinalOrderSummary AS (
    SELECT 
        o.o_orderkey,
        COUNT(li.l_orderkey) AS total_lineitems,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_revenue,
        SUM(CASE WHEN li.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returned_items,
        SUM(CASE WHEN li.l_shipdate > o.o_orderdate THEN 1 ELSE 0 END) AS late_shipments
    FROM 
        orders o 
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey
)

SELECT 
    o.o_orderkey,
    o.total_lineitems,
    o.net_revenue,
    o.returned_items,
    o.late_shipments,
    pp.p_name,
    pp.p_retailprice,
    pd.s_suppkey,
    sd.nation_name 
FROM 
    FinalOrderSummary o
LEFT JOIN 
    PotentiallyNullSuppliers pd ON pd.p_partkey = (
        SELECT 
            p.p_partkey 
        FROM 
            part p 
        WHERE 
            p.p_retailprice BETWEEN 10 AND 100
        ORDER BY 
            RANDOM() 
        LIMIT 1
    )
LEFT JOIN 
    SupplierDetails sd ON sd.s_suppkey = pd.s_suppkey
JOIN 
    RankedParts pp ON pp.p_partkey = pd.p_partkey
WHERE 
    pp.rn = 1 OR pp.p_retailprice IS NULL
ORDER BY 
    o.net_revenue DESC, 
    pp.p_name
LIMIT 50;