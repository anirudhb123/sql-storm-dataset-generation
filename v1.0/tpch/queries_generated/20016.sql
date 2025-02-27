WITH RECURSIVE PriceCTE AS (
    SELECT 
        ps_partkey, 
        ps_suppkey, 
        ps_availqty, 
        ps_supplycost,
        CAST((ps_availqty * ps_supplycost) AS DECIMAL(15,2)) AS total_cost,
        1 as level
    FROM partsupp
    WHERE ps_availqty > 10
    
    UNION ALL

    SELECT 
        ps.partkey, 
        ps.suppkey, 
        ps.availqty * 0.95 AS availqty,
        ps.supplycost * 1.05 AS supplycost,
        CAST((ps_availqty * ps_supplycost) AS DECIMAL(15,2)) + CAST((ps_availqty * ps_supplycost * 0.2) AS DECIMAL(15,2)) AS total_cost,
        level + 1
    FROM PriceCTE cte
    INNER JOIN partsupp ps ON cte.ps_partkey = ps.ps_partkey 
    WHERE level < 5
),

TotalOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS total_items
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
RegionNation AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        n.n_nationkey AS nation_id,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name, n.n_name, n.n_nationkey
    HAVING COUNT(s.s_suppkey) > 10
)

SELECT 
    p.p_partkey,
    p.p_name,
    ps_availqty,
    COALESCE(PriceCTE.total_cost, 0) AS computed_cost,
    SUM(ts.total_revenue) AS total_revenue,
    rn.region_name,
    rn.nation_name,
    rn.total_suppliers
FROM part p
LEFT JOIN PriceCTE ON p.p_partkey = PriceCTE.ps_partkey
LEFT JOIN TotalOrders ts ON ts.o_orderkey = 
    (SELECT o.o_orderkey 
     FROM orders o 
     WHERE o.o_orderdate = 
        (SELECT MAX(o2.o_orderdate) 
         FROM orders o2 
         WHERE o2.o_orderkey = o.o_orderkey))
LEFT JOIN RegionNation rn ON rn.nation_id = 
    (SELECT s_nationkey 
     FROM supplier s 
     WHERE s.s_suppkey = 
         (SELECT ps.ps_suppkey 
          FROM partsupp ps 
          WHERE ps.ps_partkey = p.p_partkey 
          LIMIT 1))
WHERE PriceCTE.total_cost IS NOT NULL 
OR ts.total_revenue IS NOT NULL
GROUP BY 
    p.p_partkey, p.p_name, ps_availqty, PriceCTE.total_cost, rn.region_name, rn.nation_name, rn.total_suppliers
ORDER BY 
    computed_cost DESC, total_revenue ASC
LIMIT 100;
