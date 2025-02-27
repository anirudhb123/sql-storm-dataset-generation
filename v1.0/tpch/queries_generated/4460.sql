WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_price,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    c.c_name AS customer_name,
    c.total_orders,
    c.total_spent,
    s.s_name AS supplier_name,
    COALESCE(si.total_supply_cost, 0) AS supplier_total_cost,
    o.o_orderkey,
    o.total_line_item_price,
    o.line_item_count
FROM 
    CustomerOrders c
LEFT JOIN 
    SupplierInfo si ON c.c_custkey = (
        SELECT 
            DISTINCT l.l_suppkey 
        FROM 
            lineitem l
        JOIN 
            orders o ON l.l_orderkey = o.o_orderkey
        WHERE 
            o.o_custkey = c.c_custkey
        LIMIT 1
    )
LEFT JOIN 
    OrderSummary o ON o.o_orderkey IN (
        SELECT 
            l.l_orderkey 
        FROM 
            lineitem l
        WHERE 
            l.l_returnflag = 'N'
    )
WHERE 
    c.total_spent > 5000
ORDER BY 
    c.total_spent DESC, si.total_supply_cost DESC;
