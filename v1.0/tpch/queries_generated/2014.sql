WITH RegionalSupplierStats AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_acct_balance,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name, r.r_name
),
OrderLineItemStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS line_item_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS row_num
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        o.orderkey, 
        o.orderdate, 
        o.total_order_value 
    FROM 
        OrderLineItemStats o 
    WHERE 
        o.line_item_count > 1 AND 
        o.total_order_value > (SELECT AVG(total_order_value) FROM OrderLineItemStats) 
)
SELECT 
    r.nation_name, 
    r.region_name,
    r.supplier_count,
    r.avg_acct_balance,
    r.total_supply_cost,
    COALESCE(t.total_order_value, 0) AS top_order_value
FROM 
    RegionalSupplierStats r
LEFT JOIN 
    (SELECT DISTINCT o.o_orderkey, o.total_order_value 
     FROM TopOrders o) t ON r.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = r.supplier_count) 
ORDER BY 
    r.region_name, r.nation_name;
