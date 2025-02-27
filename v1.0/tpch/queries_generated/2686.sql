WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N' 
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(od.total_price) AS total_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cp.c_name,
    cp.order_count,
    COALESCE(cp.total_order_value, 0) AS total_order_value,
    sp.total_supply_value,
    sp.part_count
FROM 
    CustomerOrders cp
LEFT JOIN 
    SupplierPerformance sp ON cp.order_count > 0
ORDER BY 
    cp.total_order_value DESC, sp.total_supply_value DESC;
