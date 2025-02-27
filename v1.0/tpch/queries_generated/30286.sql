WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        CASE 
            WHEN o.o_orderstatus = 'O' THEN 'Open'
            WHEN o.o_orderstatus = 'F' THEN 'Filled'
            ELSE 'Other'
        END AS order_status_detail
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01'
  
    UNION ALL

    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        CASE 
            WHEN o.o_orderstatus = 'O' THEN 'Open'
            WHEN o.o_orderstatus = 'F' THEN 'Filled'
            ELSE 'Other'
        END AS order_status_detail
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_orderkey
),

SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),

RegionalSums AS (
    SELECT
        r.r_name,
        SUM(COALESCE(ss.unique_parts, 0)) AS total_unique_parts,
        SUM(COALESCE(ss.total_supply_cost, 0)) AS total_supply_cost
    FROM region r
    LEFT JOIN SupplierStats ss ON r.r_regionkey = ss.s_nationkey
    GROUP BY r.r_name
)

SELECT 
    o.order_status_detail,
    r.r_name,
    r.total_unique_parts,
    r.total_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY r.total_supply_cost DESC) AS rank,
    (SELECT AVG(l.l_discount) 
     FROM lineitem l 
     WHERE l.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_orderstatus = 'F')) AS avg_discount
FROM OrderHierarchy o
JOIN RegionalSums r ON o.o_orderkey = r.r_name
WHERE r.total_supply_cost > 10000
  AND EXISTS (
      SELECT 1 
      FROM lineitem l 
      WHERE l.l_orderkey = o.o_orderkey AND l.l_returnflag = 'R'
  )
ORDER BY r.total_supply_cost DESC, o.o_totalprice ASC;
