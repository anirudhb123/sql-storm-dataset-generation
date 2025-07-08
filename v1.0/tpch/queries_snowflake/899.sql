WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate <= '1997-12-31'
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
CustomerStats AS (
    SELECT 
        c.c_nationkey,
        AVG(c.c_acctbal) AS avg_account_balance,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        COUNT(*) AS line_item_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name,
    COALESCE(cs.avg_account_balance, 0) AS avg_balance,
    COALESCE(cs.total_orders, 0) AS total_orders,
    ss.unique_suppliers,
    ss.total_supply_value,
    COUNT(ro.o_orderkey) AS orders_count,
    SUM(od.total_line_value) AS total_order_value
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    CustomerStats cs ON n.n_nationkey = cs.c_nationkey
LEFT JOIN 
    SupplierStats ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN 
    RankedOrders ro ON EXISTS (SELECT 1 FROM orders o WHERE ro.o_orderkey = o.o_orderkey AND o.o_orderstatus = 'O')
LEFT JOIN 
    OrderDetails od ON od.l_orderkey = ro.o_orderkey
GROUP BY 
    r.r_name, cs.avg_account_balance, cs.total_orders, ss.unique_suppliers, ss.total_supply_value
ORDER BY 
    total_order_value DESC
LIMIT 10;