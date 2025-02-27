WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 1000.00
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    COALESCE(sp.total_cost, 0) AS supplier_total_cost,
    COUNT(DISTINCT lo.o_orderkey) AS order_count,
    AVG(lo.l_extendedprice * (1 - lo.l_discount)) AS avg_revenue
FROM 
    part p
LEFT JOIN 
    lineitem lo ON p.p_partkey = lo.l_partkey
LEFT JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    RankedOrders ro ON lo.l_orderkey = ro.o_orderkey AND ro.order_rank <= 5
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND p.p_retailprice > 50.00
    AND ro.o_orderkey IS NOT NULL
GROUP BY 
    p.p_name, sp.total_cost
HAVING 
    AVG(lo.l_extendedprice * (1 - lo.l_discount)) > 100.00
ORDER BY 
    supplier_total_cost DESC, order_count DESC;
