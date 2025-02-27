WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' 
        AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' 
        AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS rnk
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
)
SELECT 
    ts.s_name,
    ps.p_name,
    ps.total_sales
FROM 
    TopSuppliers ts
JOIN 
    PartSales ps ON ts.s_suppkey = (
        SELECT 
            psupp.ps_suppkey 
        FROM 
            partsupp psupp 
        WHERE 
            psupp.ps_partkey IN (SELECT p.p_partkey FROM part p)
        ORDER BY 
            psupp.ps_supplycost DESC
        LIMIT 1
    )
WHERE 
    ts.rnk <= 5
ORDER BY 
    ts.total_sales DESC, ps.total_sales DESC;
