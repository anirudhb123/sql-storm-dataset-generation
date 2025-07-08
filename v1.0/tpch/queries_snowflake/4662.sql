
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
LineitemAnalysis AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' 
        AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    o.c_name,
    la.line_count,
    la.total_revenue,
    COALESCE(sc.total_supply_cost, 0) AS total_supply_cost
FROM 
    RankedOrders o
LEFT JOIN 
    LineitemAnalysis la ON o.o_orderkey = la.l_orderkey
LEFT JOIN 
    SupplierCosts sc ON sc.ps_partkey IN (
        SELECT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey = o.o_orderkey
    )
WHERE 
    o.order_rank <= 5
ORDER BY 
    o.o_orderdate DESC, o.o_totalprice DESC
FETCH FIRST 50 ROWS ONLY;
