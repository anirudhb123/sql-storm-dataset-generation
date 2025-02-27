WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_orderdate DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
LineItemAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS total_items,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    COALESCE(la.total_revenue, 0) AS total_revenue,
    COALESCE(sd.total_cost, 0) AS supplier_cost,
    CASE 
        WHEN la.total_revenue IS NULL THEN 'No revenue'
        ELSE 'Revenue recorded'
    END AS revenue_status
FROM 
    RankedOrders o
LEFT JOIN 
    LineItemAggregates la ON o.o_orderkey = la.l_orderkey
LEFT JOIN 
    SupplierDetails sd ON sd.s_suppkey = (
        SELECT 
            ps.ps_suppkey
        FROM 
            partsupp ps
        JOIN 
            lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE 
            l.l_orderkey = o.o_orderkey 
        LIMIT 1
    )
WHERE 
    o.rank <= 5
ORDER BY 
    o.o_orderdate DESC;