
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
        AND o.o_orderstatus IN ('O', 'F', 'P')
),
SupplierSummary AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        s.s_nationkey
),
LineItemAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.total_revenue) AS nation_revenue
    FROM 
        nation n
    LEFT JOIN 
        LineItemAggregates l ON n.n_nationkey IN (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p)))
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    ns.nation_revenue,
    ss.supplier_count,
    ss.total_supply_cost,
    ROW_NUMBER() OVER (ORDER BY ns.nation_revenue DESC) AS revenue_rank
FROM 
    region r
LEFT JOIN 
    NationStats ns ON r.r_regionkey = ns.n_nationkey 
JOIN 
    SupplierSummary ss ON ss.s_nationkey = ns.n_nationkey
WHERE 
    ns.nation_revenue IS NOT NULL
ORDER BY 
    revenue_rank
LIMIT 10;
