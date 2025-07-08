
WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderdate > oh.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('F', 'O')
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderstatus IN ('F', 'O'))
),
MaxPriceParts AS (
    SELECT 
        ps.ps_partkey, 
        MAX(ps.ps_supplycost) AS max_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
PartSales AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY p.p_partkey, p.p_name
),
QualifiedParts AS (
    SELECT 
        pp.p_partkey, 
        pp.p_name, 
        pp.total_sales 
    FROM PartSales pp
    JOIN MaxPriceParts mp ON pp.p_partkey = mp.ps_partkey
    WHERE pp.total_sales > 10000 AND mp.max_supplycost < 25
)

SELECT 
    c.c_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    SUM(qp.total_sales) AS total_spent_on_parts
FROM TopCustomers c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN QualifiedParts qp ON qp.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
WHERE o.o_orderstatus IS NULL OR o.o_orderstatus NOT IN ('C')
GROUP BY c.c_name
ORDER BY total_spent_on_parts DESC
LIMIT 10;
