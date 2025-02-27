WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
AggregatedLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_tax) AS average_tax
    FROM 
        lineitem l
    JOIN 
        RankedOrders ro ON l.l_orderkey = ro.o_orderkey
    GROUP BY 
        l.l_orderkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
)
SELECT 
    CONCAT('Order Key: ', ro.o_orderkey) AS order_info,
    ro.o_orderdate,
    ali.total_revenue,
    ali.total_quantity,
    ali.average_tax,
    CONCAT('Supplier: ', sd.s_name, ', Nation: ', sd.nation_name) AS supplier_info,
    sd.total_supply_cost
FROM 
    RankedOrders ro
JOIN 
    AggregatedLineItems ali ON ro.o_orderkey = ali.l_orderkey
JOIN 
    SupplierDetails sd ON sd.total_supply_cost > 1000
ORDER BY 
    ali.total_revenue DESC, ro.o_orderdate DESC
LIMIT 100;
