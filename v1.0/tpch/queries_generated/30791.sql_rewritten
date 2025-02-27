WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, r_comment, 0 AS level
    FROM region
    WHERE r_name = 'ASIA'
    UNION ALL
    SELECT r.r_regionkey, r.r_name, r.r_comment, rh.level + 1
    FROM region r
    JOIN RegionHierarchy rh ON r.r_regionkey = rh.level + 1
),
AggregatedSupplierData AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey, s.s_suppkey, s.s_name
),
OrderSummaries AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_price,
        COUNT(l.l_orderkey) AS item_count,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_num
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
)

SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    CASE 
        WHEN l.l_returnflag = 'R' THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    ROUND(AVG(l.l_extendedprice * (1 - l.l_discount)), 2) AS avg_price,
    SUM(CASE WHEN o.o_orderdate > cast('1998-10-01' as date) - INTERVAL '1 year' THEN l.l_quantity ELSE 0 END) AS recent_quantity,
    (SELECT COUNT(DISTINCT c.c_custkey) 
     FROM customer c 
     WHERE c.c_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_name = 'Supplier#000001')) AS customer_count
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN OrderSummaries o ON l.l_orderkey = o.o_orderkey
WHERE p.p_size BETWEEN 10 AND 50
GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, l.l_returnflag
HAVING AVG(l.l_extendedprice * (1 - l.l_discount)) > 100
ORDER BY avg_price DESC
LIMIT 10 OFFSET 5;