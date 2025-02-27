WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE '%' || SUBSTRING(oh.o_orderkey::text FROM 1 FOR 3) || '%')
    WHERE o.o_orderstatus = 'O' AND oh.level < 5
), MaxSupplied AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
)
SELECT 
    oh.o_orderkey,
    oh.o_orderdate,
    oh.o_totalprice,
    rp.p_name,
    rp.p_brand,
    CASE 
        WHEN rp.rank <= 5 THEN 'Top 5 by Price' 
        ELSE 'Others' 
    END AS price_category,
    COALESCE(MAX(ms.total_supply_cost), 0) AS max_supply_cost,
    COUNT(DISTINCT c.c_custkey) AS total_customers
FROM OrderHierarchy oh
JOIN lineitem li ON li.l_orderkey = oh.o_orderkey
LEFT JOIN RankedParts rp ON rp.p_partkey = li.l_partkey
LEFT JOIN MaxSupplied ms ON ms.ps_partkey = li.l_partkey
JOIN customer c ON c.c_custkey = oh.o_custkey
GROUP BY 
    oh.o_orderkey, 
    oh.o_orderdate, 
    oh.o_totalprice, 
    rp.p_name, 
    rp.p_brand, 
    rp.rank
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    oh.o_orderdate DESC, 
    max_supply_cost DESC;
