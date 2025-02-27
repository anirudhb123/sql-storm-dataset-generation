WITH RECURSIVE ProductHierarchy AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, 1 AS level 
    FROM part p 
    WHERE p.p_size > 0
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, ph.level + 1 
    FROM part p 
    JOIN ProductHierarchy ph ON p.p_partkey = ph.p_partkey
),
MaxSupplierCost AS (
    SELECT ps.ps_partkey, MAX(ps.ps_supplycost) AS max_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
RankedOrders AS (
    SELECT c.c_custkey, co.order_count, co.total_spent, ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM customer c
    JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
),
FilteredProducts AS (
    SELECT ph.p_partkey, ph.p_name, ph.p_retailprice, msc.max_supplycost
    FROM ProductHierarchy ph
    LEFT JOIN MaxSupplierCost msc ON ph.p_partkey = msc.ps_partkey
    WHERE ph.p_retailprice > (SELECT AVG(p_retailprice) FROM part) AND (msc.max_supplycost IS NOT NULL OR ph.p_size < 20)
),
FinalAggregation AS (
    SELECT f.p_partkey, f.p_name, SUM(lo.l_quantity) AS total_quantity_sold
    FROM FilteredProducts f
    LEFT JOIN lineitem lo ON f.p_partkey = lo.l_partkey
    GROUP BY f.p_partkey, f.p_name
)
SELECT r.rank, fa.p_partkey, fa.p_name, fa.total_quantity_sold, 
       CASE 
           WHEN fa.total_quantity_sold IS NULL THEN 'No Sales'
           WHEN fa.total_quantity_sold > 100 THEN 'High Demand'
           ELSE 'Low Demand' 
       END AS demand_category
FROM FinalAggregation fa
JOIN RankedOrders r ON fa.p_partkey = r.c_custkey
WHERE r.order_count > 5
ORDER BY r.rank, fa.total_quantity_sold DESC;
