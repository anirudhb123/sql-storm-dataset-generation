WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), 
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), 
NationSummary AS (
    SELECT 
        n.n_name AS nation,
        SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_revenue
    FROM 
        lineitem lp 
    JOIN 
        orders o ON lp.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' 
        AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        n.n_name
) 
SELECT 
    n.nation,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(n.total_revenue) AS total_revenue,
    COALESCE(SUM(sp.total_supply_value), 0) AS total_supply_value
FROM 
    NationSummary n
LEFT JOIN 
    RankedOrders ro ON n.nation = 
        (SELECT n_name FROM nation WHERE n_nationkey = ro.o_custkey)
LEFT JOIN 
    SupplierParts sp ON sp.ps_partkey IN (
        SELECT ps_partkey 
        FROM partsupp 
        WHERE ps_supplycost > 100.00
    )
GROUP BY 
    n.nation
ORDER BY 
    total_revenue DESC;
