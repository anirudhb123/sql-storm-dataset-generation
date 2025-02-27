WITH SupplierAgg AS (
    SELECT 
        ps.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts
    FROM 
        partsupp ps
    GROUP BY 
        ps.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS line_rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COALESCE(c.customer_spending, 0) AS customer_spending,
    COALESCE(s.total_supply_cost, 0) AS supplier_cost,
    l.total_price_after_discount,
    COUNT(DISTINCT l.l_orderkey) AS distinct_orders
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierAgg sagg ON s.s_suppkey = sagg.s_suppkey
LEFT JOIN 
    CustomerOrders c ON s.s_name = c.c_custkey
LEFT JOIN 
    LineItemDetails l ON l.l_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_custkey = c.c_custkey AND o.o_orderstatus = 'O'
    )
WHERE 
    l.total_price_after_discount > 0
    OR (c.order_count IS NULL AND s.total_supply_cost IS NOT NULL)
GROUP BY 
    r.r_name, n.n_name, s.s_name, c.customer_spending, s.total_supply_cost, l.total_price_after_discount
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 1
ORDER BY 
    region_name, nation_name, supplier_name;
