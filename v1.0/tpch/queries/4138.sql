
WITH NationalSales AS (
    SELECT 
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        n.n_name
),
SupplierAvailability AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        MAX(s.s_acctbal) AS max_acctbal,
        MIN(s.s_acctbal) AS min_acctbal
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    n.n_name AS nation,
    COALESCE(ns.total_sales, 0) AS total_sales,
    sa.total_avail_qty,
    ts.supplier_rank
FROM 
    nation n
LEFT JOIN 
    NationalSales ns ON n.n_name = ns.n_name
LEFT JOIN 
    SupplierAvailability sa ON sa.p_partkey = (
        SELECT p.p_partkey 
        FROM part p 
        JOIN partsupp ps ON p.p_partkey = ps.ps_partkey 
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey 
        WHERE s.s_nationkey = n.n_nationkey 
        ORDER BY ps.ps_availqty DESC 
        LIMIT 1
    )
LEFT JOIN 
    TopSuppliers ts ON ts.s_suppkey = (
        SELECT s.s_suppkey 
        FROM partsupp ps 
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey 
        WHERE s.s_nationkey = n.n_nationkey 
        GROUP BY s.s_suppkey
        ORDER BY SUM(ps.ps_supplycost) DESC 
        LIMIT 1
    )
WHERE 
    n.n_regionkey IS NOT NULL
ORDER BY 
    total_sales DESC, nation ASC;
