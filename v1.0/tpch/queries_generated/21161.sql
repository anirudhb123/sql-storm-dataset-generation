WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER(PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 20
),
TopPricedParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_retailprice
    FROM 
        RankedParts rp
    WHERE 
        rp.rn <= 5
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 5000
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) >= 10000
)
SELECT 
    so.s_name AS supplier_name,
    pp.p_name AS part_name,
    pp.p_retailprice,
    cos.c_name AS customer_name,
    cos.order_count,
    cos.total_spent,
    CASE 
        WHEN socs.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderStats) THEN 'Above Average'
        ELSE 'Below Average'
    END AS spending_category
FROM 
    SupplierInfo so
JOIN 
    partsupp ps ON so.s_suppkey = ps.ps_suppkey
JOIN 
    TopPricedParts pp ON ps.ps_partkey = pp.p_partkey
JOIN 
    CustomerOrderStats cos ON cos.order_count > 0 AND cos.c_custkey IN (
        SELECT 
            o.o_custkey 
        FROM 
            orders o 
        WHERE 
            o.o_orderdate >= DATEADD(month, -6, GETDATE())
    )
LEFT JOIN 
    CustomerOrderStats socs ON socs.c_custkey = cos.c_custkey
WHERE 
    so.nation_name IS NOT NULL AND 
    pp.p_retailprice > (
        SELECT 
            AVG(p_retailprice) FROM part WHERE p_size IS NOT NULL
    )
ORDER BY 
    pp.p_retailprice DESC, cos.total_spent DESC;
