WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS line_item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_tax) AS avg_tax
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2022-01-01' AND l.l_shipdate < DATE '2023-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    c.c_name,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(ss.total_available_qty, 0) AS total_available_qty,
    COALESCE(ss.avg_supply_cost, 0) AS avg_supply_cost,
    ls.line_item_count,
    ls.total_revenue,
    ls.avg_tax
FROM 
    RankedOrders r
LEFT JOIN 
    customer c ON r.o_custkey = c.c_custkey
LEFT JOIN 
    SupplierSummary ss ON EXISTS (
        SELECT 1 FROM partsupp ps WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_orderkey = r.o_orderkey
        )
        AND ps.ps_suppkey = ss.s_suppkey
    )
LEFT JOIN 
    LineItemStats ls ON r.o_orderkey = ls.l_orderkey
WHERE 
    r.order_rank <= 10
ORDER BY 
    r.o_orderdate DESC, 
    r.o_totalprice DESC;
