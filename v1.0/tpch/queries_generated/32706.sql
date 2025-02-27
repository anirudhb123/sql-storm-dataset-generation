WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        1 AS order_level
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        oh.order_level + 1
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE 
        o.o_orderdate < '2023-12-31'
),
CustomerTotalPrice AS (
    SELECT 
        c.c_custkey,
        c.c_name,
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
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name
),
LineItemStatistics AS (
    SELECT 
        l.l_orderkey,
        COUNT(l.l_linenumber) AS item_count,
        AVG(l.l_extendedprice) AS avg_price,
        SUM(l.l_discount) AS total_discount
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ch.o_orderkey,
    ct.c_name AS customer_name,
    sp.p_name AS product_name,
    l.item_count,
    l.avg_price,
    l.total_discount,
    (CASE 
        WHEN ct.total_spent > 1000 THEN 'High Value' 
        ELSE 'Normal Value' 
     END) AS customer_value,
    sp.total_available
FROM 
    OrderHierarchy ch
JOIN 
    CustomerTotalPrice ct ON ch.o_custkey = ct.c_custkey
LEFT JOIN 
    LineItemStatistics l ON ch.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierPartDetails sp ON l.l_orderkey = sp.p_partkey
WHERE 
    sp.total_available IS NOT NULL
ORDER BY 
    ch.o_orderkey, ct.total_spent DESC;
