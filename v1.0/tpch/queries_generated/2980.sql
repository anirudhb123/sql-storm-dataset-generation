WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate <= '2023-12-31'
), SupplierAvgCost AS (
    SELECT 
        ps.ps_suppkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100.00
    GROUP BY 
        ps.ps_suppkey
), CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 10000.00
), LineitemDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        COALESCE(l.l_discount, 0) AS discount
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-07-01'
)

SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    cs.total_orders,
    cs.total_spent,
    s.avg_supplycost,
    SUM(ld.l_extendedprice * (1 - ld.discount)) AS total_lineitem_value
FROM 
    RankedOrders r
JOIN 
    CustomerOrderSummary cs ON cs.total_orders > 2
LEFT JOIN 
    SupplierAvgCost s ON s.ps_suppkey = ANY((
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        JOIN 
            lineitem l ON l.l_partkey = ps.ps_partkey 
        WHERE 
            l.l_orderkey = r.o_orderkey
    ))
JOIN 
    LineitemDetails ld ON ld.l_orderkey = r.o_orderkey
WHERE 
    rnk = 1
GROUP BY 
    r.o_orderkey, r.o_orderdate, r.o_totalprice, cs.total_orders, cs.total_spent, s.avg_supplycost
ORDER BY 
    total_spent DESC, r.o_orderdate DESC;
