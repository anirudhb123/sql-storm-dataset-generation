WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
        JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 100.00
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
OrdersWithHighValueParts AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_partkey IN (SELECT p.p_partkey FROM HighValueParts p) 
        AND o.o_orderdate >= DATEADD(year, -1, CURRENT_DATE)
    GROUP BY 
        o.o_orderkey, o.o_totalprice
),
SupplierOrderData AS (
    SELECT 
        os.o_orderkey, 
        os.o_totalprice,
        ss.s_name AS supplier_name,
        COUNT(DISTINCT ss.s_nationkey) AS national_supplier_count
    FROM 
        OrdersWithHighValueParts os
        JOIN RankedSuppliers ss ON os.o_orderkey = ss.s_suppkey
    GROUP BY 
        os.o_orderkey, os.o_totalprice, ss.s_name
    HAVING 
        COUNT(*) > 1
)
SELECT 
    sod.o_orderkey, 
    sod.o_totalprice, 
    sod.supplier_name,
    CASE 
        WHEN sod.national_supplier_count IS NULL THEN 'No suppliers'
        WHEN sod.national_supplier_count >= 5 THEN 'Many suppliers'
        ELSE 'Few suppliers' 
    END AS supplier_status,
    ROW_NUMBER() OVER (ORDER BY sod.o_totalprice DESC) AS order_rank
FROM 
    SupplierOrderData sod
WHERE 
    sod.o_totalprice IS NOT NULL 
    AND sod.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
UNION 
SELECT 
    NULL AS o_orderkey, 
    NULL AS o_totalprice, 
    NULL AS supplier_name, 
    'Aggregated' AS supplier_status,
    COUNT(*) as order_rank
FROM 
    SupplierOrderData
WHERE 
    supplier_name IS NULL
ORDER BY 
    o_orderkey DESC NULLS LAST;
