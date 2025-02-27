WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        c.c_name,
        COUNT(li.l_orderkey) AS line_item_count,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        o.*,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS customer_rank
    FROM 
        OrderSummary o
)
SELECT 
    ps.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_size,
    COALESCE(ss.total_available_quantity, 0) AS total_available_quantity,
    COALESCE(ss.avg_supply_cost, 0) AS avg_supply_cost,
    COALESCE(ss.total_parts_supplied, 0) AS total_parts_supplied,
    t.c_custkey,
    t.c_name,
    t.line_item_count,
    t.total_revenue
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierStats ss ON ps.ps_suppkey = ss.s_suppkey
FULL OUTER JOIN 
    TopCustomers t ON p.p_partkey = (SELECT ps_partkey FROM partsupp WHERE ps_supplycost = (SELECT MIN(ps_supplycost) FROM partsupp WHERE ps_partkey = p.p_partkey))
ORDER BY 
    p.p_partkey, t.total_revenue DESC
LIMIT 100;
