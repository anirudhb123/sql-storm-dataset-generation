WITH RECURSIVE SupplyChain AS (
    SELECT 
        ps_partkey,
        ps_suppkey,
        ps_availqty,
        ps_supplycost,
        s.s_name AS supplier_name
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps_availqty > 0
    UNION ALL
    SELECT 
        ps_partkey,
        ps_suppkey,
        ps_availqty,
        ps_supplycost,
        s.s_name AS supplier_name
    FROM 
        SupplyChain sc
    JOIN 
        partsupp ps ON sc.ps_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps_availqty > 0 AND sc.ps_suppkey != ps.ps_suppkey
),
CustomerOrders AS (
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
),
RankedOrders AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.order_count,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM 
        CustomerOrders co
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_container,
    sc.supplier_name,
    r.region_name,
    ro.c_name,
    ro.total_spent
FROM 
    part p 
LEFT JOIN 
    SupplyChain sc ON p.p_partkey = sc.ps_partkey
LEFT JOIN 
    nation n ON sc.ps_suppkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    RankedOrders ro ON ro.order_count > 5
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_type = p.p_type)
    AND sc.ps_supplycost IN (SELECT DISTINCT ps_supplycost FROM partsupp ps WHERE ps_availqty < 100)
ORDER BY 
    ro.total_spent DESC, p.p_name;
