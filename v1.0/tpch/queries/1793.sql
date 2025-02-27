
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
TotalSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        l.l_orderkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        c.c_mktsegment IN ('BUILDING', 'FOB')
    GROUP BY 
        c.c_custkey
),
FinalResult AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.order_count,
        COALESCE(co.total_spent, 0) AS total_spent,
        ts.total_revenue,
        ss.s_name AS top_supplier
    FROM 
        customer c
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    LEFT JOIN 
        TotalSales ts ON ts.l_orderkey = ANY (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
    LEFT JOIN 
        RankedSuppliers ss ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT MIN(ps_partkey) FROM partsupp) LIMIT 1) 
    WHERE 
        ss.rn = 1
)
SELECT 
    f.c_custkey,
    f.c_name,
    f.order_count,
    f.total_spent,
    f.total_revenue,
    COALESCE(f.top_supplier, 'No Supplier') AS top_supplier
FROM 
    FinalResult f
WHERE 
    f.order_count > 0
ORDER BY 
    f.total_spent DESC, f.total_revenue DESC;
