WITH aggregated_orders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey
),
product_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
supplier_nation AS (
    SELECT 
        s.s_suppkey,
        n.n_name AS nation,
        SUM(s.s_acctbal) AS total_acct_bal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, n.n_name
)
SELECT 
    rp.nation AS supplier_nation,
    ps.p_name AS product_name,
    ROUND(SUM(ao.total_revenue), 2) AS total_revenue,
    SUM(ps.total_available_qty) AS total_avail_qty,
    AVG(ps.avg_supply_cost) AS avg_supply_cost,
    COUNT(DISTINCT ao.unique_customers) AS distinct_customers
FROM 
    aggregated_orders ao
JOIN 
    product_summary ps ON ao.o_orderkey IN (
        SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = ps.p_partkey
    )
JOIN 
    supplier_nation rp ON rp.s_suppkey IN (
        SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = ps.p_partkey
    )
GROUP BY 
    rp.nation, ps.p_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
