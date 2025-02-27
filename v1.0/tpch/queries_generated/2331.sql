WITH SupplierParts AS (
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
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey, 
        COUNT(*) AS item_count, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2023-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    np.n_name AS nation_name, 
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(COALESCE(sp.total_supply_cost, 0)) AS total_supplier_cost,
    SUM(COALESCE(cd.total_order_value, 0)) AS total_orders_value,
    AVG(ld.total_line_value) AS average_line_value
FROM 
    nation np
LEFT JOIN 
    customer c ON c.c_nationkey = np.n_nationkey
LEFT JOIN 
    CustomerOrders cd ON c.c_custkey = cd.c_custkey
LEFT JOIN 
    SupplierParts sp ON sp.s_suppkey IN (
        SELECT ps.ps_suppkey FROM partsupp ps 
        LEFT JOIN part p ON ps.ps_partkey = p.p_partkey 
        WHERE p.p_brand LIKE '%Brand%'
    )
LEFT JOIN 
    LineItemDetails ld ON ld.l_orderkey IN (
        SELECT o.o_orderkey FROM orders o 
        WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    )
WHERE 
    np.n_regionkey IS NOT NULL
GROUP BY 
    np.n_name
HAVING 
    SUM(COALESCE(sp.total_supply_cost, 0)) > 10000
ORDER BY 
    total_orders_value DESC, unique_customers ASC;
