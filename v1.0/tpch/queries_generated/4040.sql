WITH SupplierData AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_acctbal, 
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
), CustomerOrderData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count,
        c.c_mktsegment
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
), LineItemStats AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS line_item_count,
        MAX(l.l_shipdate) AS latest_ship_date
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    sd.nation_name,
    sd.total_avail_qty,
    sd.total_supply_cost,
    cod.total_order_value,
    cod.order_count,
    lis.total_revenue,
    lis.line_item_count,
    DATEDIFF(CURDATE(), lis.latest_ship_date) AS days_since_last_ship
FROM 
    SupplierData sd
FULL OUTER JOIN 
    CustomerOrderData cod ON sd.s_suppkey = cod.c_custkey
LEFT JOIN 
    LineItemStats lis ON lis.l_orderkey = cod.c_custkey
WHERE 
    (sd.total_avail_qty IS NOT NULL OR cod.total_order_value IS NOT NULL)
    AND (sd.total_supply_cost > 1000 OR cod.order_count > 5)
ORDER BY 
    days_since_last_ship DESC, sd.nation_name;
