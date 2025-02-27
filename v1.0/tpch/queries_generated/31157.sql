WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        0 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000.00
    
    UNION ALL
    
    SELECT 
        supp.s_suppkey,
        supp.s_name,
        supp.s_acctbal,
        sh.level + 1
    FROM 
        supplier supp
    JOIN 
        SupplierHierarchy sh ON supp.s_acctbal < sh.s_acctbal
    WHERE 
        sh.level < 3
),
PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size BETWEEN 10 AND 20
    GROUP BY 
        p.p_partkey, p.p_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rn
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_name,
    pi.total_available_qty,
    pi.average_supply_cost,
    ts.total_sales,
    (CASE 
        WHEN ts.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Exist'
    END) AS sales_status,
    ch.level AS supplier_level,
    (SELECT 
        COUNT(*)
     FROM 
        nation n
     WHERE 
        n.n_nationkey IN (SELECT s_nationkey FROM supplier WHERE s_acctbal > 10000)
    ) AS high_balance_nations
FROM 
    PartInfo pi
LEFT JOIN 
    TotalSales ts ON pi.p_partkey = ts.l_partkey
LEFT JOIN 
    SupplierHierarchy ch ON ch.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = pi.p_partkey LIMIT 1)
WHERE 
    pi.average_supply_cost < 50.00
    AND EXISTS (SELECT 1 FROM TopCustomers tc WHERE tc.rn <= 10)
ORDER BY 
    pi.total_available_qty DESC,
    ts.total_sales DESC NULLS LAST;
