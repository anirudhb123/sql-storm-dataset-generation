WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost) as rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
), 
SupplierProfit AS (
    SELECT 
        sc.s_suppkey,
        sc.s_name,
        SUM(sc.ps_availqty * sc.ps_supplycost) AS total_cost
    FROM 
        SupplyChain sc
    GROUP BY 
        sc.s_suppkey, sc.s_name
) 
SELECT 
    h.o_orderkey,
    s.s_name,
    h.total_revenue,
    sp.total_cost,
    CASE 
        WHEN h.customer_count IS NULL THEN 'No Customers'
        ELSE CAST(h.customer_count AS VARCHAR)
    END AS customer_info
FROM 
    HighValueOrders h
LEFT JOIN 
    SupplierProfit sp ON h.o_orderkey = sp.s_suppkey
JOIN 
    nation n ON sp.s_suppkey = n.n_nationkey
WHERE 
    n.n_name IN ('USA', 'Canada')
ORDER BY 
    h.total_revenue DESC,
    sp.total_cost ASC
LIMIT 10;
