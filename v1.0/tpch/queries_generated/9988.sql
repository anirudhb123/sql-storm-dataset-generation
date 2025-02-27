WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders AS o
    JOIN 
        customer AS c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
), AggregateData AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT r.r_regionkey) AS region_count,
        SUM(ro.o_totalprice) AS total_order_value,
        AVG(ro.o_totalprice) AS average_order_value
    FROM 
        RankedOrders AS ro
    JOIN 
        customer AS c ON ro.o_orderkey = c.c_custkey
    JOIN 
        nation AS n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region AS r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.order_rank <= 10
    GROUP BY 
        n.n_name
)
SELECT 
    ad.nation_name,
    ad.region_count,
    ad.total_order_value,
    ad.average_order_value,
    p.p_name,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM 
    AggregateData AS ad
JOIN 
    partsupp AS ps ON ad.nation_name = (
        SELECT n.n_name 
        FROM nation n 
        JOIN supplier s ON n.n_nationkey = s.s_nationkey
        WHERE s.s_suppkey = ps.ps_suppkey
        LIMIT 1
    )
JOIN 
    part AS p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    ad.nation_name, ad.region_count, ad.total_order_value, ad.average_order_value, p.p_name
ORDER BY 
    ad.total_order_value DESC, p.p_name
LIMIT 100;
