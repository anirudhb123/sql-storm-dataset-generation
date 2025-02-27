WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
), PartSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        p.p_partkey, p.p_name
), SupplierStats AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        COALESCE(ps.total_sales, 0) AS total_sales,
        COUNT(DISTINCT ps.p_partkey) AS parts_supplied
    FROM 
        RankedSuppliers rs
    LEFT JOIN 
        PartSales ps ON rs.s_suppkey = ps.p_partkey
    WHERE 
        rs.rank = 1
    GROUP BY 
        rs.s_suppkey, rs.s_name
)
SELECT 
    r.r_name AS region_name,
    ss.s_name,
    SUM(ss.total_sales) AS total_sales,
    COUNT(ss.parts_supplied) AS total_parts,
    AVG(s.s_acctbal) AS avg_account_balance
FROM 
    SupplierStats ss
JOIN 
    supplier s ON ss.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name, ss.s_name
HAVING 
    SUM(ss.total_sales) > 100000
ORDER BY 
    total_sales DESC, avg_account_balance DESC;
