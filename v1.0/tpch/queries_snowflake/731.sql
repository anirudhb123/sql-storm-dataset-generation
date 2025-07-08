WITH RevenueCTE AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1996-01-01' AND l_shipdate < DATE '1997-01-01'
    GROUP BY 
        l_orderkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s 
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        SupplierDetails s
    WHERE 
        s.total_supply_cost > 100000
)
SELECT 
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(r.total_revenue) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    MAX(s.s_acctbal) AS max_supplier_acctbal,
    SUM(CASE 
            WHEN s.s_acctbal IS NULL THEN 0 
            ELSE s.s_acctbal 
        END) AS total_account_balance
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    RevenueCTE r ON o.o_orderkey = r.l_orderkey
LEFT JOIN 
    HighValueSuppliers s ON s.s_suppkey = (SELECT ps.ps_suppkey 
                                             FROM partsupp ps 
                                             JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
                                             WHERE l.l_orderkey = o.o_orderkey 
                                             LIMIT 1)
WHERE 
    o.o_orderstatus IN ('O', 'F') 
    AND c.c_mktsegment = 'BUILDING'
GROUP BY 
    c.c_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;