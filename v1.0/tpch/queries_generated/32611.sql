WITH RECURSIVE part_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
nation_region_summary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MIN(o.o_orderdate) AS first_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
customer_revenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(os.total_revenue), 0) AS total_customer_revenue
    FROM 
        customer c
    LEFT JOIN 
        order_summary os ON c.c_custkey = os.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    c.c_custkey,
    c.c_name,
    cr.total_customer_revenue,
    nrs.region_name,
    ps.total_availqty,
    ps.total_supplycost
FROM 
    customer_revenue cr
JOIN 
    customer c ON cr.c_custkey = c.c_custkey
JOIN 
    nation_region_summary nrs ON c.c_nationkey = nrs.n_nationkey
JOIN 
    part_summary ps ON ps.total_availqty > 1000
ORDER BY 
    cr.total_customer_revenue DESC,
    nrs.unique_suppliers DESC
LIMIT 10;
