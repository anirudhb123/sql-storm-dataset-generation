WITH CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartCost AS (
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
PopularParts AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity_sold,
        COUNT(DISTINCT l.l_orderkey) AS distinct_orders
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' 
        AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY 
        l.l_partkey
    HAVING 
        SUM(l.l_quantity) > 100
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    p.p_size,
    COALESCE(spc.total_supply_cost, 0) AS supplier_cost,
    COALESCE(c.total_spent, 0) AS customer_spending,
    pp.total_quantity_sold,
    ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY pp.total_quantity_sold DESC) AS rank_within_type
FROM 
    part p
LEFT JOIN 
    SupplierPartCost spc ON p.p_partkey = spc.s_suppkey
LEFT JOIN 
    CustomerOrders c ON c.total_spent > 5000
LEFT JOIN 
    PopularParts pp ON p.p_partkey = pp.l_partkey
WHERE 
    (p.p_retailprice > 50 OR pp.total_quantity_sold IS NOT NULL)
    AND p.p_container NOT LIKE '%box%'
ORDER BY 
    p.p_type, rank_within_type;
