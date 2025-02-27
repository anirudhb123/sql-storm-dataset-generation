WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),

CustomerTotal AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),

SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, SUM(pss.ps_supplycost * p.p_retailprice) AS total_cost
    FROM supplier s
    JOIN partsupp p ON s.s_suppkey = p.ps_suppkey
    JOIN part p ON p.p_partkey = p.ps_partkey
    GROUP BY s.s_suppkey, s.s_name
)

SELECT
    c.c_name,
    COALESCE(SUM(l.l_extendedprice), 0) AS total_lineitem_price,
    COUNT(DISTINCT oh.o_orderkey) AS total_orders,
    RANK() OVER (ORDER BY COALESCE(SUM(l.l_extendedprice), 0) DESC) AS rank_by_spending,
    sd.s_name AS supplier_name,
    sd.total_cost AS supplier_cost
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
LEFT JOIN 
    SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
WHERE 
    c.c_acctbal IS NOT NULL AND
    o.o_orderdate >= '2022-01-01' AND
    (sd.total_cost IS NULL OR sd.total_cost > 1000)
GROUP BY 
    c.c_name, sd.s_name, sd.total_cost
HAVING 
    total_orders > 5
ORDER BY 
    total_lineitem_price DESC;
