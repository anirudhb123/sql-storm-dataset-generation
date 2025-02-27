WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey, 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rank 
    FROM 
        partsupp ps 
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey 
), 
HighValueSuppliers AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        rs.s_suppkey, 
        rs.s_name, 
        rs.s_acctbal 
    FROM 
        part p 
    JOIN 
        RankedSuppliers rs ON p.p_partkey = rs.ps_partkey 
    WHERE 
        rs.rank <= 3 
), 
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue 
    FROM 
        orders o 
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey 
    WHERE 
        li.l_shipdate >= DATE '2023-01-01' AND 
        li.l_shipdate < DATE '2023-02-01' 
    GROUP BY 
        o.o_orderkey 
), 
SupplierOrderRevenue AS (
    SELECT 
        hvs.s_suppkey, 
        hvs.s_name, 
        SUM(os.revenue) AS total_revenue 
    FROM 
        HighValueSuppliers hvs 
    JOIN 
        OrderSummary os ON hvs.p_partkey IN (
            SELECT ps.ps_partkey 
            FROM partsupp ps 
            WHERE ps.ps_suppkey = hvs.s_suppkey
        )
    GROUP BY 
        hvs.s_suppkey, 
        hvs.s_name 
) 
SELECT 
    s.s_name, 
    COALESCE(s.total_revenue, 0) AS total_revenue 
FROM 
    (SELECT DISTINCT s_suppkey, s_name FROM supplier) s 
LEFT JOIN 
    SupplierOrderRevenue sr ON s.s_suppkey = sr.s_suppkey 
ORDER BY 
    total_revenue DESC 
LIMIT 10;
