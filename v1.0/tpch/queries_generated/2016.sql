WITH SupplierStats AS (
    SELECT
        s_nationkey,
        COUNT(DISTINCT s_suppkey) AS total_suppliers,
        AVG(s_acctbal) AS avg_acctbal,
        SUM(CASE WHEN s_acctbal IS NULL THEN 0 ELSE s_acctbal END) AS non_null_acctbal_sum
    FROM
        supplier
    GROUP BY
        s_nationkey
),
PartsInfo AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(p.p_retailprice) AS avg_retail_price
    FROM
        partsupp ps
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        ps.ps_partkey
),
OrderSummary AS (
    SELECT
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_custkey
)
SELECT
    n.n_name AS nation_name,
    COALESCE(s.total_suppliers, 0) AS total_suppliers,
    COALESCE(s.avg_acctbal, 0) AS avg_acctbal,
    COALESCE(s.non_null_acctbal_sum, 0) AS non_null_acctbal_sum,
    COALESCE(p.total_available_qty, 0) AS total_available_qty,
    COALESCE(p.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(p.avg_retail_price, 0) AS avg_retail_price,
    o.total_spent,
    o.order_count
FROM
    nation n
LEFT JOIN
    SupplierStats s ON n.n_nationkey = s.s_nationkey
LEFT JOIN
    PartsInfo p ON p.ps_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey IN (SELECT s_suppkey FROM supplier WHERE s_nationkey = n.n_nationkey))
LEFT JOIN
    OrderSummary o ON o.o_custkey IN (SELECT c_custkey FROM customer WHERE c_nationkey = n.n_nationkey)
ORDER BY
    nation_name;
