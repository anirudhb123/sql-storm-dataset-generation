WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        lo.l_partkey,
        lo.l_suppkey,
        lo.l_quantity,
        lo.l_extendedprice,
        ps.ps_supplycost,
        p.p_brand,
        p.p_type,
        r.r_name AS region_name
    FROM 
        lineitem lo
    JOIN 
        partsupp ps ON lo.l_partkey = ps.ps_partkey 
    JOIN 
        part p ON lo.l_partkey = p.p_partkey
    JOIN 
        supplier s ON lo.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        lo.l_orderkey IN (SELECT o_orderkey FROM RankedOrders WHERE price_rank <= 10)
)
SELECT 
    od.region_name,
    SUM(od.l_extendedprice * (1 - od.l_discount)) AS revenue,
    COUNT(DISTINCT od.l_orderkey) AS order_count,
    AVG(od.l_quantity) AS avg_quantity,
    MAX(od.l_extendedprice) AS max_price
FROM 
    OrderDetails od
GROUP BY 
    od.region_name
HAVING 
    SUM(od.l_extendedprice * (1 - od.l_discount)) > 10000
ORDER BY 
    revenue DESC;
