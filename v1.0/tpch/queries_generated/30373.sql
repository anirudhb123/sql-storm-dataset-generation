WITH RECURSIVE SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost,
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
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_amount,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerRanking AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS revenue_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ps.p_partkey,
    p.p_name,
    SUM(ps.ps_availqty) AS total_available_qty,
    COALESCE(MAX(ss.total_supply_cost), 0) AS max_supply_cost,
    COALESCE(COUNT(DISTINCT od.o_orderkey), 0) AS total_orders,
    (SELECT AVG(total_order_amount) FROM OrderDetails) AS avg_order_amount,
    CASE 
        WHEN cu.revenue_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierSummary ss ON ps.ps_suppkey = ss.s_suppkey
LEFT JOIN 
    OrderDetails od ON ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = od.o_orderkey)
LEFT JOIN 
    customer cu ON od.o_custkey = cu.c_custkey
WHERE 
    p.p_retailprice BETWEEN 50 AND 200
GROUP BY 
    ps.p_partkey, p.p_name, cu.revenue_rank
HAVING 
    total_available_qty > 10
ORDER BY 
    total_available_qty DESC, max_supply_cost DESC;
