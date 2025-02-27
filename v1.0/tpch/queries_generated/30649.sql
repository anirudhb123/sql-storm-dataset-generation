WITH RECURSIVE TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
), 
NationSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
), 
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS adjusted_price
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
)
SELECT 
    n.n_name,
    p.p_name,
    SUM(fs.adjusted_price) AS total_optimized_sales,
    COALESCE(SUM(ts.total_cost), 0) AS total_supplier_cost
FROM 
    FilteredParts fs
JOIN 
    TopSuppliers ts ON fs.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey)
JOIN 
    NationSales n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = fs.p_partkey) LIMIT 1)
GROUP BY 
    n.n_name, p.p_name
ORDER BY 
    total_optimized_sales DESC, total_supplier_cost ASC
LIMIT 10;
