WITH RankedProducts AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_availqty) DESC) AS brand_rank
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_name, p.p_brand, p.p_mfgr
),
TopProducts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_mfgr,
        rp.total_available,
        rp.total_cost
    FROM 
        RankedProducts rp
    WHERE 
        rp.brand_rank <= 3
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    tp.p_name,
    tp.p_brand,
    tp.total_available,
    tp.total_cost,
    cos.c_name,
    cos.total_orders,
    cos.total_spent
FROM 
    TopProducts tp
CROSS JOIN 
    CustomerOrderStats cos
ORDER BY 
    tp.total_cost DESC, cos.total_spent DESC;
