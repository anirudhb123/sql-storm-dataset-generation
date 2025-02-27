WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
SupplierPart AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) as rn_supplier
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        RankedParts p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderdate
)
SELECT 
    cp.c_name,
    cp.total_spent,
    qsp.p_name,
    ISNULL(sp.s_name, 'No Supplier') AS supplier_name,
    CASE 
        WHEN cp.order_count > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_type
FROM 
    CustomerOrders cp
LEFT JOIN 
    SupplierPart sp ON cp.order_count = sp.rn_supplier
RIGHT JOIN 
    RankedParts rp ON sp.ps_partkey = rp.p_partkey
JOIN 
    (SELECT 
        p_partkey,
        COUNT(DISTINCT p_brand) AS brand_count
     FROM 
        RankedParts
     WHERE 
        rn = 1
     GROUP BY 
        p_partkey
     HAVING 
        COUNT(*) > 1) AS qsp ON rp.p_partkey = qsp.p_partkey
WHERE 
    cp.total_spent > 1000
    AND rp.p_size >= (SELECT AVG(p_size) FROM part WHERE p_retailprice < 100)
ORDER BY 
    cp.total_spent DESC, rp.p_retailprice ASC;
