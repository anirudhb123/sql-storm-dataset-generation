WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate > DATEADD(month, -12, GETDATE())
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        MIN(ps.ps_supplycost) AS min_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
QualifiedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(sp.total_avail_qty) AS supplier_total_avail_qty
    FROM 
        supplier s
    JOIN 
        SupplierParts sp ON s.s_suppkey = sp.ps_suppkey
    WHERE 
        s.s_acctbal > (
            SELECT 
                AVG(s2.s_acctbal)
            FROM 
                supplier s2
            WHERE 
                s2.s_nationkey = s.s_nationkey
        )
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
)
SELECT 
    n.n_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COALESCE(SUM(ps.l_extendedprice * (1 - ps.l_discount)), 0) AS total_sales,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers
FROM 
    nation n
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    orders o ON o.o_custkey = c.c_custkey
LEFT JOIN 
    lineitem ps ON o.o_orderkey = ps.l_orderkey
JOIN 
    QualifiedSuppliers s ON ps.l_suppkey = s.s_suppkey
WHERE 
    o.o_orderstatus = 'F' 
    AND s.supplier_total_avail_qty > 1000
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_sales DESC;
