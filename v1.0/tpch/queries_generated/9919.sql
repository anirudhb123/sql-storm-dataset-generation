WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_nationkey, 
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_price
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), 
TopOrders AS (
    SELECT 
        ro.o_orderkey, 
        ro.o_orderdate, 
        ro.o_totalprice, 
        ro.c_nationkey
    FROM 
        RankedOrders ro
    WHERE 
        ro.rank_price <= 10
), 
SupplierDetails AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
OrderLineItems AS (
    SELECT 
        li.l_orderkey, 
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_sales
    FROM 
        lineitem li
    GROUP BY 
        li.l_orderkey
)
SELECT 
    TO_CHAR(oo.o_orderdate, 'YYYY-MM') AS order_month,
    n.n_name AS nation,
    COUNT(DISTINCT oo.o_orderkey) AS total_orders,
    SUM(COALESCE(oli.net_sales, 0)) AS total_net_sales,
    SUM(COALESCE(sd.total_supply_cost, 0)) AS total_supply_cost
FROM 
    TopOrders oo
LEFT JOIN 
    OrderLineItems oli ON oo.o_orderkey = oli.l_orderkey
LEFT JOIN 
    nation n ON oo.c_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierDetails sd ON oo.o_orderkey = sd.ps_partkey
GROUP BY 
    order_month, n.n_name
ORDER BY 
    order_month, total_net_sales DESC;
