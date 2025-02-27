WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, 1 AS level
    FROM region
    WHERE r_regionkey = 1
    
    UNION ALL
    
    SELECT r.r_regionkey, r.r_name, rh.level + 1
    FROM region r
    JOIN RegionHierarchy rh ON r.r_regionkey = rh.r_regionkey + 1
),
SupplierStats AS (
    SELECT s.s_suppkey,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS average_cost,
           COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrder AS (
    SELECT c.c_custkey,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 0
    GROUP BY c.c_custkey
),
LineItemStats AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
           MAX(l.l_shipdate) AS latest_ship_date
    FROM lineitem l
    GROUP BY l.l_orderkey
),
AggregatedData AS (
    SELECT 
        c.c_name AS customer_name,
        ss.total_available,
        ss.average_cost,
        co.order_count,
        co.total_spent,
        li.total_value,
        CASE 
            WHEN co.order_count > 10 THEN 'Frequent'
            ELSE 'Occasional'
        END AS customer_type
    FROM CustomerOrder co
    JOIN SupplierStats ss ON co.c_custkey = ss.s_suppkey
    JOIN LineItemStats li ON co.order_count = li.l_orderkey
    JOIN customer c ON co.c_custkey = c.c_custkey
    WHERE ss.total_available IS NOT NULL
)

SELECT 
    rh.r_name AS region_name,
    ad.customer_name,
    ad.total_spent,
    ad.total_value,
    ad.customer_type
FROM AggregatedData ad
JOIN region r ON r.r_regionkey = (
    SELECT n.n_regionkey
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    WHERE c.c_custkey = ad.custkey
)
LEFT OUTER JOIN SupplierStats ss ON ad.total_available = ss.total_available
WHERE ad.total_value > 1000
ORDER BY region_name, total_value DESC;
