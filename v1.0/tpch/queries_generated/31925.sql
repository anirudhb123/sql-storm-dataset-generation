WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01'
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerSpend AS (
    SELECT c.c_custkey, c.c_name,
           SUM(o.o_totalprice) AS total_spend,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueOrders AS (
    SELECT oh.o_orderkey, oh.o_custkey, oh.o_totalprice, c.c_name
    FROM OrderHierarchy oh
    JOIN CustomerSpend c ON oh.o_custkey = c.c_custkey
    WHERE oh.o_totalprice > 10000
),
RegionalSummary AS (
    SELECT r.r_name, SUM(s.total_supply_cost) AS region_supply_cost
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
)
SELECT DISTINCT
    h.o_orderkey,
    h.o_totalprice,
    h.c_name,
    COALESCE(r.region_supply_cost, 0) AS supply_cost_in_region,
    CASE
        WHEN h.o_totalprice > r.region_supply_cost THEN 'High Value'
        ELSE 'Regular Value'
    END AS order_value_category
FROM HighValueOrders h
LEFT JOIN RegionalSummary r ON h.o_custkey IN (
    SELECT c.c_custkey 
    FROM customer c
    WHERE c.c_nationkey IN (
        SELECT n.n_nationkey 
        FROM nation n 
        JOIN region rr ON n.n_regionkey = rr.r_regionkey
        WHERE rr.r_name = 'ASIA'
    )
)
ORDER BY h.o_orderkey;
