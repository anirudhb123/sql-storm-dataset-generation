WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
),
HighSalesParts AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_name, p.p_brand, p.p_type
    HAVING 
        total_cost > (SELECT AVG(total_sales) FROM TotalSales)
),
NationSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_nation_sales
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    ns.n_name,
    ns.total_nation_sales,
    rs.s_name,
    rs.s_acctbal AS supplier_account_balance
FROM 
    HighSalesParts p
JOIN 
    RankedSuppliers rs ON rs.rn = 1 AND rs.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = p.ps_partkey
    )
JOIN 
    NationSales ns ON ns.total_nation_sales > 10000
ORDER BY 
    ns.total_nation_sales DESC, p.p_name ASC;
