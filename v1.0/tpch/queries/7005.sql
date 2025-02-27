WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        c.c_nationkey,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_totalprice > 50000 AND 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(*) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1996-01-01' AND 
        l.l_shipdate < '1997-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.s_suppkey, 
    r.s_name, 
    hv.o_orderkey, 
    hv.o_totalprice, 
    la.net_revenue, 
    la.item_count
FROM 
    RankedSuppliers r
JOIN 
    HighValueOrders hv ON r.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = hv.o_orderkey))
JOIN 
    LineItemAnalysis la ON hv.o_orderkey = la.l_orderkey
WHERE 
    r.rank <= 5
ORDER BY 
    hv.o_totalprice DESC, 
    la.net_revenue DESC;