WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name IN ('FRANCE', 'GERMANY', 'USA')
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        n.n_name AS nation_name
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank <= 3
),
ProductDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        ps.ps_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_name LIKE '%metal%'
)
SELECT 
    ts.s_name AS supplier_name,
    ts.nation_name,
    pd.p_name AS product_name,
    pd.ps_supplycost,
    pd.ps_availqty,
    CONCAT('Supplier ', ts.s_name, ' from ', ts.nation_name, 
           ' offers ', pd.p_name, ' at a cost of ', 
           CAST(pd.ps_supplycost AS VARCHAR), ' with availability of ', 
           CAST(pd.ps_availqty AS VARCHAR)) AS supplier_offer_details
FROM 
    TopSuppliers ts
JOIN 
    ProductDetails pd ON ts.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = pd.p_partkey
    )
ORDER BY 
    ts.nation_name, 
    ts.s_acctbal DESC;
