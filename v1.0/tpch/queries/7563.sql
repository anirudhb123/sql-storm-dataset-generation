WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_amount,
        COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.p_partkey,
    r.p_name,
    r.p_brand,
    r.p_type,
    r.p_retailprice,
    sd.s_name AS supplier_name,
    os.total_order_amount,
    os.unique_customers
FROM 
    RankedParts r
JOIN 
    SupplierDetails sd ON r.rnk = 1 AND r.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey)
JOIN 
    OrderSummary os ON os.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = r.p_partkey)
WHERE 
    r.p_retailprice < (SELECT MAX(p3.p_retailprice) FROM part p3) * 0.9
ORDER BY 
    r.p_retailprice DESC, sd.total_supply_cost ASC;
