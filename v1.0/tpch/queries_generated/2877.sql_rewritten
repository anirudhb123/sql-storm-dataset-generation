WITH SupplierOrderSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ss.total_sales,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        SupplierOrderSummary ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.s_acctbal,
    t.total_sales,
    t.supplier_rank,
    COALESCE(r.r_name, 'Unknown') AS region_name
FROM 
    TopSuppliers t
LEFT JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = t.s_suppkey LIMIT 1)
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    t.supplier_rank <= 10
ORDER BY 
    t.total_sales DESC;