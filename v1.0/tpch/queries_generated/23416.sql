WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS RankAsc,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal ASC) AS RankDesc
    FROM 
        supplier s
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice,
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year,
        COUNT(DISTINCT l.l_orderkey) OVER (PARTITION BY o.o_custkey) AS total_orders_per_customer
    FROM 
        orders o 
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('F', 'O') 
        AND o.o_totalprice > (
            SELECT AVG(o2.o_totalprice) 
            FROM orders o2 
            WHERE o2.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
        )
)
SELECT 
    DISTINCT r.r_name,
    ps.ps_partkey,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CASE 
        WHEN SUM(l.l_quantity) IS NULL THEN 0 
        ELSE SUM(l.l_quantity) 
    END AS total_quantity,
    COALESCE((
        SELECT MAX(s.s_acctbal) 
        FROM RankedSuppliers s 
        WHERE s.RankAsc <= 3 
        AND s.s_suppkey IN (
            SELECT DISTINCT ps.ps_suppkey 
            FROM partsupp ps 
            WHERE ps.ps_partkey = p.p_partkey
        )
    ), 0) AS max_supplier_acctbal
FROM 
    lineitem l 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey 
JOIN 
    part p ON ps.ps_partkey = p.p_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31' 
    AND (r.r_comment IS NOT NULL OR r.r_comment <> '')
GROUP BY 
    r.r_name, ps.ps_partkey, p.p_name 
HAVING 
    SUM(l.l_extendedprice) > 10000 
    AND COUNT(DISTINCT o.o_orderkey) > 5 
ORDER BY 
    r.r_name, total_revenue DESC;
