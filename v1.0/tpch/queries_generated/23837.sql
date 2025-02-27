WITH RankedSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        s_acctbal,
        RANK() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank_acctbal
    FROM 
        supplier
),
TopSuppliers AS (
    SELECT 
        s_suppkey,
        s_name
    FROM 
        RankedSuppliers
    WHERE 
        rank_acctbal <= 3
),
TotalOrderValues AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_supplycost,
        p.p_size,
        p.p_retailprice
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size BETWEEN 1 AND 10
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        CASE 
            WHEN o.o_orderstatus = 'O' THEN 'Open'
            ELSE 'Closed'
        END AS order_status_desc,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -1, CURRENT_DATE)
)
SELECT 
    t.s_suppkey,
    t.s_name,
    COUNT(DISTINCT fo.o_orderkey) AS total_orders,
    AVG(tpv.total_value) AS avg_order_value,
    SUM(CASE WHEN s.ps_supplycost > tpv.total_value THEN 1 ELSE 0 END) AS overpriced_parts
FROM 
    TopSuppliers t
LEFT JOIN 
    SupplierParts s ON t.s_suppkey = s.ps_suppkey
LEFT JOIN 
    TotalOrderValues tpv ON s.ps_partkey IN (
        SELECT 
            l.l_partkey 
        FROM 
            lineitem l 
        JOIN 
            FilteredOrders fo ON l.l_orderkey = fo.o_orderkey
    )
GROUP BY 
    t.s_suppkey, t.s_name
HAVING 
    SUM(CASE WHEN s.ps_supplycost IS NULL THEN 1 ELSE 0 END) > 0
    OR COUNT(DISTINCT fo.o_orderkey) > 5
ORDER BY 
    avg_order_value DESC, total_orders DESC
LIMIT 10;
