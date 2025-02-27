WITH supplier_part_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS distinct_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
), nation_summary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
), order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    n.n_name,
    ns.region_name,
    s.s_name,
    s.total_available,
    s.avg_supply_cost,
    os.total_revenue,
    os.unique_customers,
    ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY os.total_revenue DESC) AS revenue_rank
FROM 
    nation_summary ns
JOIN 
    supplier_part_summary s ON ns.total_suppliers = (SELECT COUNT(DISTINCT s2.s_suppkey) FROM supplier s2 WHERE s2.s_nationkey = ns.n_nationkey)
JOIN 
    order_summary os ON os.total_revenue > 0
WHERE 
    s.total_available > 1000
ORDER BY 
    ns.region_name, revenue_rank;
