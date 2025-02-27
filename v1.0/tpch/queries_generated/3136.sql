WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
LineItemsSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS total_items,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.o_orderstatus,
    COALESCE(ls.total_revenue, 0) AS total_revenue,
    COALESCE(ls.total_items, 0) AS total_items,
    COALESCE(ls.avg_quantity, 0) AS avg_quantity,
    COALESCE(hs.total_supplycost, 0) AS supplier_total_cost
FROM 
    RankedOrders r
LEFT JOIN 
    LineItemsSummary ls ON r.o_orderkey = ls.l_orderkey
LEFT JOIN 
    HighValueSuppliers hs ON hs.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
        WHERE l.l_orderkey = r.o_orderkey
    )
WHERE 
    r.rn <= 10
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;
