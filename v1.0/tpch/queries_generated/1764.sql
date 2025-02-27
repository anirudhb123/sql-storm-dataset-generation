WITH SupplyCostSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
OrderSummary AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_quantity) AS total_supplied_quantity
    FROM 
        supplier s
    JOIN 
        lineitem l ON s.s_suppkey = l.l_suppkey
    WHERE 
        l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        total_supplied_quantity DESC
    LIMIT 10
)
SELECT 
    p.p_name,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(os.total_order_value, 0) AS total_order_value,
    COALESCE(coc.order_count, 0) AS order_count,
    ts.total_supplied_quantity
FROM 
    part p
LEFT JOIN 
    SupplyCostSummary ss ON p.p_partkey = ss.ps_partkey
LEFT JOIN 
    OrderSummary os ON os.o_orderkey IN (
        SELECT o_orderkey 
        FROM orders 
        WHERE o_orderkey IN (SELECT o_orderkey FROM lineitem WHERE l_partkey = p.p_partkey)
    )
LEFT JOIN 
    CustomerOrderCount coc ON coc.c_custkey IN (
        SELECT o_custkey 
        FROM orders 
        WHERE o_orderkey IN (
            SELECT l_orderkey 
            FROM lineitem 
            WHERE l_partkey = p.p_partkey
        )
    )
LEFT JOIN 
    TopSuppliers ts ON ts.s_suppkey IN (
        SELECT l_suppkey 
        FROM lineitem 
        WHERE l_partkey = p.p_partkey
    )
WHERE 
    p.p_size > 20
ORDER BY 
    total_supply_cost DESC, total_order_value DESC;
