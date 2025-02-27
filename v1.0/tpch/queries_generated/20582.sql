WITH Ranked_Suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
Filtered_Orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_shippriority
    FROM orders o
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
      AND (o.o_orderstatus = 'O' OR o.o_orderstatus = 'F')
      AND o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderdate < CURRENT_DATE)
),
Lineitem_Data AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
Supplier_Orders AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_qty,
        SUM(ps.ps_supplycost) AS total_cost
    FROM partsupp ps
    WHERE ps.ps_supplycost IS NOT NULL
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    s.s_name AS supplier_name,
    o.o_orderkey,
    o.o_totalprice,
    o.o_orderdate,
    COALESCE(ld.total_revenue, 0) AS order_revenue,
    CASE 
        WHEN COALESCE(ld.total_revenue, 0) > (SELECT AVG(total_revenue) FROM Lineitem_Data) THEN 'Above Average'
        ELSE 'Below Average'
    END AS revenue_status,
    AVG(s.s_acctbal) OVER (PARTITION BY r.r_regionkey) AS avg_acctbal_per_region
FROM part p
JOIN Supplier_Orders su ON p.p_partkey = su.ps_partkey
JOIN Ranked_Suppliers s ON su.ps_suppkey = s.s_suppkey
JOIN Filtered_Orders o ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = s.s_nationkey)
LEFT JOIN Lineitem_Data ld ON o.o_orderkey = ld.l_orderkey
JOIN region r ON s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
WHERE p.p_retailprice BETWEEN 50.00 AND 200.00
  AND (r.r_name LIKE 'South%' OR r.r_name IS NULL)
ORDER BY revenue_status DESC, o.o_orderdate ASC
FETCH FIRST 100 ROWS ONLY;
