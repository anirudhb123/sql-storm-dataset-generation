WITH RECURSIVE RegionCTE AS (
    SELECT r_regionkey, r_name, r_comment, 1 AS level
    FROM region
    WHERE r_name LIKE '%N%'
    UNION ALL
    SELECT r.r_regionkey, r.r_name, r.r_comment, level + 1
    FROM region r
    JOIN RegionCTE cte ON r.r_regionkey = (cte.r_regionkey - 1)
    WHERE cte.level < 5
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
LineItemDetails AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_price,
           COUNT(*) filter (WHERE l.l_returnflag = 'R') AS return_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
OrderStats AS (
    SELECT o.o_orderkey, 
           o.o_orderstatus,
           ld.net_price,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY ld.net_price DESC) AS status_rank,
           DENSE_RANK() OVER (ORDER BY ld.net_price DESC) AS overall_rank
    FROM orders o
    LEFT JOIN LineItemDetails ld ON o.o_orderkey = ld.l_orderkey
),
SupplierRegion AS (
    SELECT sr.s_suppkey, sr.total_supply_cost, r.r_name
    FROM SupplierDetails sr
    JOIN nation n ON sr.s_suppkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_comment IS NOT NULL
),
FinalSummary AS (
    SELECT 
        s.s_name AS supplier_name, 
        r.r_name AS region_name, 
        os.o_orderstatus AS order_status,
        os.net_price AS total_price,
        os.status_rank,
        os.overall_rank,
        COALESCE(ld.return_count, 0) AS total_returns
    FROM OrderStats os
    LEFT JOIN SupplierRegion sr ON sr.total_supply_cost > 10000
    LEFT JOIN region r ON sr.s_suppkey = r.r_regionkey
    LEFT JOIN lineitem ld ON ld.l_orderkey = os.o_orderkey
    WHERE sr.total_supply_cost IS NOT NULL 
      AND (os.o_orderstatus IS NULL OR os.o_orderstatus IN ('O', 'F'))
)
SELECT 
    fs.supplier_name,
    fs.region_name,
    SUM(fs.total_price) AS total_orders,
    AVG(fs.total_returns) AS avg_returns,
    COUNT(DISTINCT fs.o_orderstatus) AS distinct_status
FROM FinalSummary fs
GROUP BY fs.supplier_name, fs.region_name
HAVING COUNT(DISTINCT fs.o_orderstatus) > 1
ORDER BY total_orders DESC, fs.supplier_name ASC
LIMIT 10;
