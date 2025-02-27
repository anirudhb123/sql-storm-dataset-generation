WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_container, p_retailprice, p_size,
           CAST(p_name AS varchar(100)) AS full_name
    FROM part
    WHERE p_size = (SELECT MAX(p_size) FROM part)

    UNION ALL

    SELECT p.p_partkey, p.p_name, p.p_container, p.p_retailprice, p.p_size,
           CONCAT(ph.full_name, ' > ', p.p_name) AS full_name
    FROM part p
    JOIN PartHierarchy ph ON p.p_partkey = ph.p_partkey + 1  -- Assumed hierarchy
)

SELECT n.n_name AS nation_name,
       COUNT(DISTINCT s.s_suppkey) AS supplier_count,
       SUM(ps.ps_availqty) AS total_available_qty,
       AVG(l.l_extendedprice) AS avg_lineitem_price,
       MAX(l.l_shipdate) AS last_ship_date,
       CASE 
           WHEN SUM(l.l_quantity) > 1000 THEN 'High Volume'
           ELSE 'Low Volume'
       END AS volume_category,
       ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice) DESC) AS rank
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
WHERE l.l_returnflag = 'N'
  AND l.l_discount BETWEEN 0.05 AND 0.2
  AND l.l_shipdate >= DATE '2023-01-01'
  AND l.l_shipdate <= DATE '2023-12-31'
GROUP BY n.n_name
HAVING COUNT(DISTINCT s.s_suppkey) > 5
  AND SUM(ps.ps_availqty) > 500
ORDER BY nation_name, total_available_qty DESC
LIMIT 10;
