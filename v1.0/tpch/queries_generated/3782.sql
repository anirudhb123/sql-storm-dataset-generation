WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderLineDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(*) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        l.l_orderkey
),
FilteredOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        od.net_revenue,
        od.item_count
    FROM 
        RankedOrders ro
    LEFT JOIN 
        OrderLineDetails od ON ro.o_orderkey = od.l_orderkey
    WHERE 
        ro.order_rank <= 10 AND
        (od.net_revenue IS NOT NULL OR ro.o_totalprice > 10000)
)
SELECT 
    fo.o_orderkey,
    fo.o_orderdate,
    COALESCE(fo.net_revenue, 0) AS net_revenue,
    fo.item_count,
    CONCAT('Order total: $', FORMAT(fo.o_totalprice, 2)) AS formatted_total_price,
    avg(sd.total_supply_cost) OVER () AS avg_supply_cost
FROM 
    FilteredOrders fo
LEFT JOIN 
    SupplierDetails sd ON sd.total_supply_cost > 500
WHERE 
    fo.item_count IS NOT NULL
ORDER BY 
    fo.o_orderdate DESC, 
    fo.o_totalprice DESC;
