WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC) as rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
), OrderLineItems AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue
    FROM 
        lineitem lo
    GROUP BY 
        lo.l_orderkey
), FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 100
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 5
), FinalResults AS (
    SELECT 
        r.r_name AS region_name,
        SUM(oli.total_revenue) AS total_revenue,
        COUNT(DISTINCT ro.o_orderkey) AS order_count,
        AVG(p.supplier_count) AS avg_supplier_per_part
    FROM 
        RankedOrders ro
    JOIN 
        OrderLineItems oli ON ro.o_orderkey = oli.l_orderkey
    JOIN 
        supplier s ON s.s_suppkey = ro.o_custkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        FilteredParts p ON p.p_partkey = oli.l_orderkey
    GROUP BY 
        r.r_name
    ORDER BY 
        total_revenue DESC
)
SELECT 
    region_name, 
    total_revenue, 
    order_count, 
    avg_supplier_per_part
FROM 
    FinalResults
WHERE 
    total_revenue > 1000000
LIMIT 10;
