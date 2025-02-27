WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
), 
region_stats AS (
    SELECT 
        r.r_name, 
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
), 
part_supplier_info AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_availqty, 
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), 
order_details AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT ll.l_suppkey) AS unique_suppliers,
        SUM(ll.l_extendedprice * (1 - ll.l_discount)) AS total_line_revenue
    FROM orders o
    JOIN lineitem ll ON o.o_orderkey = ll.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F') 
    AND ll.l_discount BETWEEN 0.05 AND 0.20
    GROUP BY o.o_orderkey
)

SELECT 
    r.r_name,
    COALESCE(rs.top_supplier_name, 'No Supplier') AS top_supplier_name,
    IFNULL(rs.top_supplier_balance, 0) AS top_supplier_balance,
    ps.total_availqty,
    ps.avg_supplycost,
    od.unique_suppliers,
    od.total_line_revenue,
    CASE 
        WHEN od.total_line_revenue > 1000 THEN 'High Revenue'
        WHEN od.total_line_revenue IS NULL THEN 'No Revenue'
        ELSE 'Standard Revenue'
    END AS revenue_category
FROM region_stats r
LEFT JOIN (
    SELECT 
        rs.s_nationkey, 
        rs.s_name AS top_supplier_name, 
        rs.s_acctbal AS top_supplier_balance
    FROM ranked_suppliers rs
    WHERE rs.rnk = 1
) rs ON r.r_regionkey = rs.s_nationkey
JOIN part_supplier_info ps ON ps.ps_partkey IN (
    SELECT ll.l_partkey 
    FROM lineitem ll 
    JOIN orders o ON ll.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
)
JOIN order_details od ON od.o_orderkey = (
    SELECT MIN(o.o_orderkey) 
    FROM orders o 
    WHERE o.o_orderstatus = 'F'
    AND o.o_orderkey IN (SELECT ll.l_orderkey FROM lineitem ll WHERE ll.l_returnflag = 'N')
)
ORDER BY r.r_name, od.total_line_revenue DESC;
