WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        s.s_name AS supplier_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, s.s_name
),
FilteredOrders AS (
    SELECT 
        o.*,
        r.r_name AS region_name
    FROM 
        RankedOrders o
    JOIN 
        nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_orderkey)
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.order_rank = 1
)
SELECT 
    fo.o_orderkey,
    fo.customer_name,
    fo.supplier_name,
    fo.total_revenue,
    fo.o_orderdate,
    fo.region_name
FROM 
    FilteredOrders fo
WHERE 
    fo.total_revenue > 10000
ORDER BY 
    fo.total_revenue DESC
LIMIT 100;
