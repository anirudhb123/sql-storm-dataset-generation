WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
PartSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_price
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        AVG(o.o_totalprice) > 500
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        RankedSuppliers s
    WHERE 
        s.rnk <= 5
)
SELECT 
    p.p_partkey,
    p.p_name,
    ps.total_cost,
    ps.supplier_count,
    co.total_spent,
    co.avg_order_price,
    NVL(hvs.s_name, 'No Supplier') AS supplier_name,
    CASE 
        WHEN co.total_spent > 1000 THEN 'High Value Customer'
        WHEN co.total_spent <= 1000 AND co.total_spent > 500 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment
FROM 
    PartSummary ps
LEFT JOIN 
    HighValueSuppliers hvs ON ps.supplier_count > 0
LEFT JOIN 
    CustomerOrders co ON ps.p_partkey IN (
        SELECT 
            l.l_partkey 
        FROM 
            lineitem l 
        JOIN 
            orders o ON l.l_orderkey = o.o_orderkey 
        WHERE 
            o.o_orderstatus = 'O'
    )
WHERE 
    ps.total_cost IS NOT NULL AND 
    (hvs.s_acctbal IS NULL OR hvs.s_acctbal > 2000)
ORDER BY 
    ps.total_cost DESC, co.total_spent DESC;
