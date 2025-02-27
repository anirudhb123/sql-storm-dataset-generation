WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
supplier_part_info AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey, s.s_name, p.p_brand, p.p_type
),
nation_stats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbalance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    ns.n_name,
    ns.supplier_count,
    ns.total_acctbalance,
    COUNT(ro.o_orderkey) FILTER (WHERE ro.revenue_rank <= 5) AS top_revenue_orders
FROM 
    region r
JOIN 
    nation_stats ns ON ns.n_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
LEFT JOIN 
    ranked_orders ro ON ns.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = ro.o_orderkey) 
GROUP BY 
    r.r_name, ns.n_name, ns.supplier_count, ns.total_acctbalance
ORDER BY 
    r.r_name, ns.total_acctbalance DESC;
