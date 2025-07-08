
WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 0 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE oh.level < 5
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent, 
           LISTAGG(DISTINCT n.n_name, ', ') WITHIN GROUP (ORDER BY n.n_name) AS nation_names
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY c.c_custkey, c.c_name
),
ProductPriceHistogram AS (
    SELECT p.p_size, COUNT(*) AS count,
           ROUND(AVG(p.p_retailprice), 2) AS avg_retail_price,
           SUM(CASE WHEN p.p_retailprice < 10 THEN 1 ELSE 0 END) AS below_10
    FROM part p
    GROUP BY p.p_size
)
SELECT DISTINCT
    ch.o_orderkey,
    cs.order_count,
    cs.total_spent,
    rs.s_name AS top_supplier,
    pp.avg_retail_price,
    pp.below_10
FROM OrderHierarchy ch
JOIN CustomerStats cs ON ch.o_custkey = cs.c_custkey
LEFT JOIN RankedSuppliers rs ON rs.rank = 1
JOIN ProductPriceHistogram pp ON ch.o_orderkey % pp.count = 0
WHERE cs.total_spent IS NOT NULL 
AND pp.avg_retail_price BETWEEN 5 AND 50
ORDER BY cs.total_spent DESC, pp.below_10 DESC;
