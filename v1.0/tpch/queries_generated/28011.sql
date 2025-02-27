WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_comment,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%steel%'
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
    HAVING 
        COUNT(ps.ps_partkey) > 5
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS purchase_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rp.p_name,
    rp.p_brand,
    ts.s_name AS supplier_name,
    ts.total_parts,
    cp.c_name AS customer_name,
    cp.purchase_count,
    cp.total_spent
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey)
JOIN 
    CustomerPurchases cp ON cp.total_spent > 1000
WHERE 
    rp.rank <= 3
ORDER BY 
    rp.p_brand, cp.total_spent DESC;
