WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
nation_suppliers AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
region_nations AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(rn.total_revenue) AS region_revenue,
    nav.total_acctbal AS total_supplier_acctbal
FROM 
    ranked_orders rn
JOIN 
    orders o ON rn.o_orderkey = o.o_orderkey
JOIN 
    nation_suppliers nav ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = nav.n_nationkey)
JOIN 
    region_nations r ON nav.total_acctbal > 10000
JOIN 
    nation n ON r.nation_count > 1 AND n.n_nationkey = nav.n_nationkey
GROUP BY 
    r.r_name, n.n_name, nav.total_acctbal
ORDER BY 
    region_revenue DESC, order_count DESC;
