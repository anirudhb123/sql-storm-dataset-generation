WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name
    FROM 
        SupplierSummary s
    WHERE 
        total_avail_qty > (SELECT AVG(total_avail_qty) FROM SupplierSummary)
    AND 
        rank <= 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        o.o_orderdate,
        DENSE_RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    os.total_order_value,
    os.o_orderdate,
    ss.avg_acctbal
FROM 
    HighValueSuppliers s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    OrderSummary os ON s.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate >= '2023-01-01')
        )
        GROUP BY ps.ps_suppkey 
        ORDER BY SUM(ps.ps_supplycost) DESC 
        LIMIT 1
    )
WHERE 
    os.order_rank <= 10
ORDER BY 
    region_name, total_order_value DESC;
