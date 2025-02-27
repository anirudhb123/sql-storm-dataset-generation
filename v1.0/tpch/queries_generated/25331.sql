WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
TopSuppliers AS (
    SELECT 
        rs.region_name,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 3
),
SupplierComments AS (
    SELECT 
        ts.region_name,
        ts.s_name,
        ts.s_acctbal,
        CONCAT('Top Supplier: ', ts.s_name, ' with balance: ', ts.s_acctbal) AS comment
    FROM 
        TopSuppliers ts
)
SELECT 
    c.c_name AS customer_name,
    o.o_orderkey,
    lc.l_returnflag,
    sc.comment
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem lc ON o.o_orderkey = lc.l_orderkey
JOIN 
    SupplierComments sc ON lc.l_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = lc.l_partkey LIMIT 1)
WHERE 
    lc.l_returnflag = 'N'
ORDER BY 
    c.c_name, o.o_orderkey;
