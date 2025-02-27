
WITH PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        s.s_acctbal,
        s.s_comment,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_name LIKE '%rubber%'
),
CustomerOrderInfo AS (
    SELECT 
        o.o_orderkey,
        c.c_name AS customer_name,
        c.c_acctbal,
        c.c_comment,
        o.o_orderdate,
        o.o_totalprice
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_totalprice > 500
),
BenchmarkData AS (
    SELECT 
        psi.p_partkey,
        psi.supplier_name,
        coi.customer_name,
        coi.o_orderkey,
        coi.o_totalprice,
        psi.ps_availqty,
        psi.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY psi.p_partkey ORDER BY coi.o_totalprice DESC) AS rank_order
    FROM 
        PartSupplierInfo psi
    JOIN 
        CustomerOrderInfo coi ON psi.ps_availqty > 100
)
SELECT 
    p.p_partkey,
    p.p_name,
    COUNT(b.o_orderkey) AS order_count,
    SUM(b.o_totalprice) AS total_revenue,
    AVG(b.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT b.customer_name, ', ') AS customer_names
FROM 
    BenchmarkData b
JOIN 
    part p ON b.p_partkey = p.p_partkey
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    COUNT(b.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;
