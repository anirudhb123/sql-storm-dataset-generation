WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
    AND 
        n.n_name IS NOT NULL
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (
            SELECT 
                AVG(o2.o_totalprice) 
            FROM 
                orders o2 
            WHERE 
                o2.o_orderdate >= DATE '2023-01-01')
),
SupplierPartStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
QualifiedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        s.s_name,
        s.s_acctbal,
        t.total_available_qty,
        t.avg_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        SupplierPartStats t ON p.p_partkey = t.ps_partkey
    WHERE 
        p.p_retailprice > 50.00 
    AND 
        s.s_suppkey IS NULL
    OR 
        t.total_available_qty < 100
)
SELECT 
    q.p_partkey,
    q.p_name,
    q.p_retailprice,
    COALESCE(q.s_name, 'No Supplier') AS supplier_name,
    q.total_available_qty,
    q.avg_supply_cost,
    CASE 
        WHEN q.total_available_qty IS NULL THEN 'Not Available'
        WHEN q.total_available_qty < 50 THEN 'Critical Stock'
        ELSE 'Sufficient Stock'
    END AS stock_status
FROM 
    QualifiedParts q
WHERE 
    (SELECT COUNT(*) FROM HighValueOrders h) > 0
ORDER BY 
    q.p_retailprice DESC, 
    q.total_available_qty ASC
FETCH FIRST 10 ROWS ONLY
UNION ALL
SELECT 
    NULL AS p_partkey,
    'Aggregate Total' AS p_name,
    SUM(q.p_retailprice) AS p_retailprice,
    'N/A' AS supplier_name,
    SUM(q.total_available_qty) AS total_available_qty,
    AVG(q.avg_supply_cost) AS avg_supply_cost,
    'Aggregate' AS stock_status
FROM 
    QualifiedParts q
HAVING 
    SUM(q.total_available_qty) > 1000;
