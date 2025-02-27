WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), FilteredCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE 
        o.o_orderstatus IN ('O', 'P') 
    AND 
        l.l_shipdate >= '2023-01-01' 
    GROUP BY 
        c.c_custkey, c.c_name
), SupplierPartCounts AS (
    SELECT 
        ps.ps_partkey, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps 
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    c.c_name, 
    COUNT(o.o_orderkey) AS order_count, 
    SUM(o.o_totalprice) AS total_order_value, 
    COALESCE(SUM(r.s_acctbal), 0) AS total_supplier_balance
FROM 
    customer c 
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey 
LEFT JOIN 
    RankedSuppliers r ON r.s_suppkey IN (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        JOIN 
            SupplierPartCounts spc ON ps.ps_partkey = spc.ps_partkey 
        WHERE 
            spc.supplier_count > 1
    )
WHERE 
    c.c_acctbal > (
        SELECT 
            AVG(c_sub.c_acctbal) 
        FROM 
            customer c_sub 
        WHERE 
            c_sub.c_mktsegment = c.c_mktsegment
    ) 
AND 
    c.c_nationkey IN (
        SELECT 
            n.n_nationkey 
        FROM 
            nation n 
        WHERE 
            n.n_comment LIKE '%wonderful%'
    )
GROUP BY 
    c.c_name
HAVING 
    COUNT(o.o_orderkey) > 5 
    OR 
    (SELECT COUNT(*) FROM orders o_sub WHERE o_sub.o_custkey = c.c_custkey) = 0
ORDER BY 
    total_order_value DESC
LIMIT 10;
