WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, n.n_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        MAX(l.l_shipdate) AS latest_ship_date
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    sd.s_name,
    sd.nation_name,
    co.c_name,
    co.order_count,
    co.total_order_value,
    lis.net_revenue,
    lis.latest_ship_date
FROM 
    SupplierDetails sd
JOIN 
    CustomerOrders co ON co.total_order_value > 10000
JOIN 
    LineItemSummary lis ON sd.total_supply_cost > 50000
ORDER BY 
    net_revenue DESC, co.order_count DESC
LIMIT 10;
