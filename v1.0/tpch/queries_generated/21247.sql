WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.n_nationkey)
),
AvailableParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        SUM(ps.ps_availqty) > 0
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1' YEAR
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
)
SELECT 
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    ap.p_name AS product_name,
    ap.p_retailprice,
    ro.total_order_value,
    CASE 
        WHEN ro.total_order_value >= ap.p_retailprice THEN 'Order Value Exceeds Price'
        WHEN ro.total_order_value IS NULL THEN 'No Recent Orders'
        ELSE 'Order Value Insufficient'
    END AS order_status,
    COUNT(DISTINCT ap.p_partkey) OVER (PARTITION BY rs.s_nationkey) AS total_parts_per_nation
FROM 
    RankedSuppliers rs
FULL OUTER JOIN 
    AvailableParts ap ON rs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = ap.p_partkey ORDER BY ps.ps_supplycost LIMIT 1)
LEFT JOIN 
    RecentOrders ro ON rs.s_suppkey = (SELECT l.l_suppkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_orderkey = ro.o_orderkey LIMIT 1)
WHERE 
    rs.suppplier_rank <= 3
ORDER BY 
    rs.s_nationkey, ap.p_partkey
LIMIT 100;
