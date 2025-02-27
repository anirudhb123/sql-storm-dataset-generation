WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        r.r_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, r.r_name
)
SELECT 
    p.p_name,
    sr.s_name,
    cr.r_name,
    cr.order_count,
    COUNT(ro.o_orderkey) AS recent_orders,
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_sales,
    CASE 
        WHEN total_sales IS NULL THEN 0 
        ELSE total_sales 
    END AS adjusted_sales
FROM 
    part p
LEFT JOIN 
    SupplierParts sr ON p.p_partkey = sr.ps_partkey
LEFT JOIN 
    CustomerRegion cr ON cr.c_custkey IN (
        SELECT 
            c.c_custkey 
        FROM 
            customer c 
        WHERE 
            c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    )
LEFT JOIN 
    lineitem lp ON lp.l_partkey = p.p_partkey
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey = lp.l_orderkey
WHERE 
    (cr.order_count IS NULL OR cr.order_count > 0)
    AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    p.p_name, sr.s_name, cr.r_name, cr.order_count
ORDER BY 
    total_sales DESC, p.p_name;
