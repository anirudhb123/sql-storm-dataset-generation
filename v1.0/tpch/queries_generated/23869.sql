WITH SupplierCosts AS (
    SELECT 
        ps.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL AND 
        ps.ps_availqty > 0
    GROUP BY 
        ps.s_suppkey
), HighValueSuppliers AS (
    SELECT 
        s_suppkey, 
        total_cost, 
        part_count 
    FROM 
        SupplierCosts 
    WHERE 
        total_cost > (SELECT AVG(total_cost) FROM SupplierCosts)
), CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F' AND 
        o.o_totalprice IS NOT NULL
)
SELECT 
    n.n_name,
    SUM(CASE WHEN lo.l_returnflag = 'R' THEN lo.l_extendedprice * (1 - lo.l_discount) ELSE 0 END) AS returned_sales,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_sales,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    DENSE_RANK() OVER (ORDER BY SUM(lo.l_extendedprice * (1 - lo.l_discount)) DESC) AS sales_rank
FROM 
    lineitem lo
JOIN 
    CustomerOrders co ON lo.l_orderkey = co.o_orderkey
JOIN 
    nation n ON co.c_nationkey = n.n_nationkey
LEFT JOIN 
    HighValueSuppliers hvs ON lo.l_suppkey = hvs.s_suppkey
WHERE 
    n.n_name IS NOT NULL AND 
    lo.l_shipdate >= DATEADD(month, -6, GETDATE())
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT co.o_orderkey) > 5 AND 
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) IS NOT NULL
ORDER BY 
    sales_rank
LIMIT 10;
