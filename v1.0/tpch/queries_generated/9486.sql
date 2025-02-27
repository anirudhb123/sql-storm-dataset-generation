WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty,
        RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) as price_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 50.00
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    rp.p_name,
    rp.p_retailprice,
    ts.s_name AS supplier_name,
    ts.total_cost,
    co.c_name AS customer_name,
    co.total_spent
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON rp.price_rank <= 5
JOIN 
    CustomerOrders co ON ts.s_suppkey = co.c_custkey
WHERE 
    rp.ps_availqty > 50
ORDER BY 
    rp.p_retailprice DESC,
    ts.total_cost ASC;
