
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    ns.supplier_count,
    ns.total_balance,
    ro.total_revenue,
    ro.o_orderkey
FROM 
    region r
JOIN 
    NationStats ns ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = ns.n_nationkey)
LEFT JOIN 
    RankedOrders ro ON ns.supplier_count > 10 AND ns.total_balance > 50000
ORDER BY 
    r.r_name, ns.n_name, ro.total_revenue DESC
FETCH FIRST 100 ROWS ONLY;
