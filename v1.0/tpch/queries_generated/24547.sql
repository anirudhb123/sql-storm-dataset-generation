WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, 0 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'F'
    
    UNION ALL
    
    SELECT o.o_orderkey, oh.o_custkey, o.o_orderdate, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
), RankedLineItems AS (
    SELECT 
        li.l_orderkey,
        li.l_partkey,
        li.l_quantity, 
        li.l_extendedprice,
        RANK() OVER (PARTITION BY li.l_orderkey ORDER BY li.l_extendedprice DESC) AS price_rank,
        SUM(li.l_quantity) OVER (PARTITION BY li.l_orderkey) AS total_quantity
    FROM lineitem li
    WHERE li.l_returnflag = 'N'
      AND li.l_discount BETWEEN 0.05 AND 0.15
), SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        COALESCE(SUM(ps.ps_supplycost), 0) AS total_supplycost,
        COUNT(DISTINCT s.s_nationkey) AS nation_count
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    RLD.l_orderkey,
    RLD.total_quantity,
    COALESCE(SPD.total_supplycost / NULLIF(SPD.nation_count, 0), 0) AS avg_supply_cost,
    COUNT(DISTINCT O.hierarchy_order) AS order_hierarchy_count,
    CASE 
        WHEN AVG(RLD.l_extendedprice) > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS value_category
FROM part p
LEFT JOIN RankedLineItems RLD ON p.p_partkey = RLD.l_partkey
LEFT JOIN SupplierPartDetails SPD ON p.p_partkey = SPD.ps_partkey
LEFT JOIN (
    SELECT oh.o_orderkey, COUNT(*) AS hierarchy_order
    FROM OrderHierarchy oh
    GROUP BY oh.o_orderkey
) O ON RLD.l_orderkey = O.o_orderkey
GROUP BY p.p_partkey, p.p_name, RLD.l_orderkey, RLD.total_quantity, SPD.total_supplycost, SPD.nation_count
HAVING SUM(RLD.l_extendedprice) > 10000
ORDER BY p.p_partkey, RLD.l_orderkey;
