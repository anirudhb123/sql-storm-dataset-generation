WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) as rnk
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 20.00
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
SupplierNation AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_nationkey,
        n.n_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    rp.p_name,
    rp.ps_supplycost,
    COUNT(co.o_orderkey) AS num_orders,
    SUM(co.total_spent) AS total_revenue,
    sn.n_name AS supplier_nation
FROM 
    RankedParts rp
JOIN 
    CustomerOrders co ON rp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = rp.ps_supplycost LIMIT 1)
JOIN 
    SupplierNation sn ON rp.ps_supplycost = (SELECT min(ps2.ps_supplycost) FROM partsupp ps2 WHERE ps2.ps_partkey = rp.p_partkey)
WHERE 
    rp.rnk = 1
GROUP BY 
    rp.p_name, rp.ps_supplycost, sn.n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
