WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
OrderLineDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate < CURRENT_DATE
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    ol.net_revenue,
    ol.avg_quantity,
    s.s_name,
    COALESCE(sc.total_supply_cost, 0) AS total_supply_cost,
    CASE 
        WHEN r.order_rank <= 10 THEN 'Top Order'
        ELSE 'Regular Order'
    END AS order_category
FROM 
    RankedOrders r
LEFT JOIN 
    OrderLineDetails ol ON r.o_orderkey = ol.l_orderkey
LEFT JOIN 
    supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN 
                                    (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#33'))
LEFT JOIN 
    SupplierCosts sc ON sc.ps_partkey IN 
        (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = r.o_orderkey)
WHERE 
    r.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
ORDER BY 
    r.o_orderdate DESC, total_supply_cost DESC;
