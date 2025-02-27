WITH RECURSIVE part_supplier_summary AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        MAX(ps.ps_supplycost) AS max_supplycost,
        CURRENT_DATE AS today
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, 
        ps.ps_suppkey
),
nation_agg AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS average_acctbal
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
order_line_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_tax) AS average_tax,
        COUNT(l.l_orderkey) AS line_item_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
joined_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.total_available,
        na.n_name,
        ol.total_revenue,
        ol.line_item_count,
        ol.order_rank
    FROM 
        part p
    LEFT JOIN 
        part_supplier_summary ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        nation_agg na ON na.n_nationkey IN (
            SELECT DISTINCT s.s_nationkey
            FROM supplier s 
            JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
            WHERE ps.ps_partkey = p.p_partkey
        )
    LEFT JOIN 
        order_line_summary ol ON ol.o_orderkey IN (
            SELECT o.o_orderkey
            FROM orders o 
            JOIN lineitem l ON o.o_orderkey = l.l_orderkey
            WHERE l.l_partkey = p.p_partkey
        )
    WHERE 
        p.p_retailprice IS NOT NULL
        AND (ps.total_available IS NOT NULL OR ol.total_revenue IS NOT NULL)
)
SELECT 
    j.p_partkey,
    j.p_name,
    COALESCE(j.total_available, 0) AS available_quantity,
    j.n_name AS supplier_nation,
    j.total_revenue AS order_revenue,
    j.line_item_count,
    CASE 
        WHEN j.order_rank = 1 THEN 'Top Order'
        ELSE 'Other Order'
    END AS order_type,
    CONCAT('Report created on: ', j.today::text) AS report_date
FROM 
    joined_summary j
ORDER BY 
    COALESCE(j.total_revenue, 0) DESC,
    j.line_item_count ASC
LIMIT 100;
