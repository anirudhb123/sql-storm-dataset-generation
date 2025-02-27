WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, 1 AS level
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, c.c_name, level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON oh.o_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate < CURRENT_DATE - INTERVAL '30 days'
),
SupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank,
           COALESCE(ps.total_supply_cost, 0) AS supply_cost
    FROM part p
    LEFT JOIN SupplierStats ps ON p.p_partkey = ps.ps_partkey
),
FilteredOrders AS (
    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, oh.c_name,
           CONCAT('Customer: ', oh.c_name, ' - Order Date: ', oh.o_orderdate) AS order_info
    FROM OrderHierarchy oh
    WHERE oh.level <= 5
)
SELECT fo.order_info, rp.p_name, rp.p_brand, rp.p_retailprice, rp.supply_cost
FROM FilteredOrders fo
JOIN RankedParts rp ON rp.price_rank <= 10
WHERE rp.p_retailprice > 100 AND rp.supply_cost IS NOT NULL
ORDER BY fo.o_orderdate DESC, rp.p_retailprice ASC
LIMIT 100;
