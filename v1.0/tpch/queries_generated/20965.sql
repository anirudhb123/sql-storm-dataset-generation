WITH RECURSIVE CTE_Nations AS (
    SELECT n_nationkey, n_name, n_regionkey
    FROM nation
    WHERE n_name = 'FRANCE'
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey
    FROM nation n
    JOIN CTE_Nations c ON n.n_regionkey = c.n_regionkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS supplied_parts_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > 0
    GROUP BY s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
AggregatedData AS (
    SELECT 
        ns.n_name,
        ss.s_name,
        ss.total_supply_cost,
        os.total_revenue,
        CASE 
            WHEN os.total_revenue IS NULL THEN 'No Orders'
            WHEN ss.total_supply_cost > COALESCE(os.total_revenue, 0) THEN 'Profitability Issue'
            ELSE 'Profitable'
        END AS profitability_status
    FROM CTE_Nations ns
    LEFT JOIN SupplierStats ss ON ns.n_nationkey = ss.s_suppkey
    LEFT JOIN OrderStats os ON ss.s_suppkey = (SELECT s.s_suppkey FROM supplier s WHERE s.s_name = ss.s_name)
)
SELECT 
    a.n_name AS nation_name,
    a.s_name AS supplier_name,
    a.total_supply_cost,
    a.total_revenue,
    a.profitability_status
FROM AggregatedData a
WHERE a.total_supply_cost IS NOT NULL
  AND (a.profitability_status != 'No Orders' OR a.total_supply_cost > 10000)
ORDER BY a.n_name, a.s_name;
