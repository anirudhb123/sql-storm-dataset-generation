WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
), SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COALESCE(NULLIF(AVG(ps.ps_supplycost), 0), 'N/A') AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), OrderDetail AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_value,
        COUNT(DISTINCT lo.l_suppkey) AS distinct_suppliers
    FROM lineitem lo
    WHERE lo.l_shipdate BETWEEN CURRENT_DATE - INTERVAL '1 year' AND CURRENT_DATE
    GROUP BY lo.l_orderkey
), NationSplits AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        CASE 
            WHEN n.n_name ILIKE '%land%' THEN 'Land Nation'
            ELSE 'Other Nation'
        END AS nation_type
    FROM nation n
), ResultSummary AS (
    SELECT 
        ps.s_suppkey,
        ss.part_count,
        ss.total_supply_value,
        od.total_value,
        ns.nation_type,
        RANK() OVER (PARTITION BY ns.nation_type ORDER BY ss.total_supply_value DESC) AS rank_within_nation
    FROM SupplierSummary ss
    LEFT JOIN OrderDetail od ON ss.s_suppkey = od.l_orderkey
    LEFT JOIN partsupp ps ON ss.s_suppkey = ps.ps_suppkey
    JOIN NationSplits ns ON ps.ps_partkey = (SELECT MIN(p.p_partkey) FROM part p WHERE p.p_partkey = ps.ps_partkey)
    WHERE ss.avg_supply_cost IS NOT NULL AND od.total_value > 5000
)
SELECT 
    rs.s_suppkey,
    rs.part_count,
    rs.total_supply_value,
    rs.total_value,
    rs.nation_type,
    rs.rank_within_nation
FROM ResultSummary rs
WHERE rs.rank_within_nation <= 10 
   OR (rs.total_supply_value IS NULL AND rs.part_count > 5)
ORDER BY rs.nation_type, rs.total_supply_value DESC, rs.total_value ASC;
