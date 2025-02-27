WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
    GROUP BY s.s_suppkey, s.s_name
    HAVING COUNT(DISTINCT ps.ps_partkey) > 2
),
MixedLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        STRING_AGG(DISTINCT l.l_comment, '; ') AS all_comments
    FROM lineitem l
    WHERE l.l_returnflag = 'N' 
    GROUP BY l.l_orderkey
),
OuterJoinResult AS (
    SELECT 
        fo.o_orderkey,
        fo.o_orderstatus,
        coalesce(ml.net_revenue, 0) AS net_revenue,
        COALESCE(fs.total_supply_cost, (SELECT MAX(ps.ps_supplycost) FROM partsupp ps)) AS fallback_cost,
        ml.all_comments
    FROM RankedOrders fo
    LEFT JOIN MixedLineItems ml ON fo.o_orderkey = ml.l_orderkey
    LEFT JOIN FilteredSuppliers fs ON fs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_size > 15 LIMIT 1))
    WHERE fo.rn = 1
),
FinalSelection AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.net_revenue,
        o.fallback_cost,
        CASE 
            WHEN o.net_revenue IS NULL AND o.fallback_cost IS NULL THEN 'No Data'
            ELSE 'Data Available'
        END AS data_availability
    FROM OuterJoinResult o
)
SELECT 
    f.o_orderkey,
    f.o_orderstatus,
    f.net_revenue,
    f.fallback_cost,
    f.data_availability,
    CASE 
        WHEN f.net_revenue > 1000 THEN 'High Revenue'
        WHEN f.net_revenue BETWEEN 500 AND 1000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM FinalSelection f
WHERE f.data_availability = 'Data Available' 
ORDER BY f.net_revenue DESC;
