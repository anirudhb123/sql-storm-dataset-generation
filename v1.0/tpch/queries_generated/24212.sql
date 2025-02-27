WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        0 AS depth,
        ROW_NUMBER() OVER(PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        oh.o_orderkey,
        oh.o_custkey,
        oh.depth + 1,
        ROW_NUMBER() OVER(PARTITION BY oh.o_custkey ORDER BY oh.o_orderkey DESC) AS rn
    FROM 
        OrderHierarchy oh
    JOIN 
        orders o ON oh.o_custkey = o.o_custkey 
    WHERE 
        o.o_orderstatus = 'O' AND oh.depth < 5
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierStats AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    cs.c_name,
    cs.total_orders,
    cs.total_spent,
    cs.avg_order_value,
    p.p_name,
    pss.total_available,
    pss.total_cost,
    CASE 
        WHEN cs.avg_order_value IS NULL THEN 'No orders'
        ELSE CAST(cs.avg_order_value AS VARCHAR) || ' as avg order value'
    END AS order_value_message,
    ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS rank,
    COALESCE(pss.total_available, 0) AS non_null_avail_qty,
    COALESCE(pss.total_cost, 0.00) AS non_null_total_cost
FROM 
    CustomerStats cs
JOIN 
    lineitem li ON li.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = cs.c_custkey)
JOIN 
    PartSupplierStats pss ON li.l_partkey = pss.p_partkey
JOIN 
    part p ON li.l_partkey = p.p_partkey
WHERE 
    cs.total_orders > 10 
    AND (pss.total_available > 100 OR pss.total_cost IS NULL)
ORDER BY 
    cs.total_spent DESC
LIMIT 100 OFFSET 0;
