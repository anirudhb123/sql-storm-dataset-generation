
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
),
CustomerCountry AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation,
        CUME_DIST() OVER (PARTITION BY n.n_name ORDER BY c.c_acctbal DESC) AS customer_distribution
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    p.p_retailprice,
    COALESCE(sa.total_available, 0) AS total_available,
    cc.nation AS customer_nation,
    hvo.total_value AS order_value
FROM 
    RankedParts p 
LEFT JOIN 
    SupplierAvailability sa ON p.p_partkey = sa.ps_partkey
LEFT JOIN 
    HighValueOrders hvo ON p.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = hvo.o_orderkey)
JOIN 
    CustomerCountry cc ON hvo.o_custkey = cc.c_custkey
WHERE 
    p.rank <= 5 
    AND p.p_retailprice > 50.00
ORDER BY 
    p.p_brand, order_value DESC;
