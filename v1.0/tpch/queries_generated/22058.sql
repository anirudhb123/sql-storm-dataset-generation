WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_cost,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_brand
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL
),
OrderLineItems AS (
    SELECT 
        o.o_orderkey,
        COUNT(li.l_orderkey) AS total_line_items,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_value,
        AVG(li.l_quantity) AS avg_quantity
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    c.c_name,
    COALESCE(c.total_orders, 0) AS total_orders,
    COALESCE(c.total_spent, 0) AS total_spent,
    COALESCE(ols.total_line_items, 0) AS total_line_items,
    COALESCE(ols.total_value, 0) AS total_value,
    COUNT(DISTINCT rs.s_suppkey) AS number_of_suppliers,
    COUNT(DISTINCT CASE WHEN rs.rank_cost <= 3 THEN rs.s_suppkey END) AS top_suppliers_count
FROM 
    CustomerOrders c
FULL OUTER JOIN 
    OrderLineItems ols ON c.total_orders = ols.total_line_items
LEFT JOIN 
    RankedSuppliers rs ON c.total_spent > 10000
WHERE 
    rs.total_supplycost IS NOT NULL 
    AND (c.total_orders > 0 OR c.total_orders IS NULL)
GROUP BY 
    c.c_name, ols.total_line_items, ols.total_value
ORDER BY 
    total_spent DESC, c.c_name;

