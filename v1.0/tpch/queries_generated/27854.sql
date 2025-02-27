WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        CONCAT('Supplier: ', s.s_name, ', Phone: ', TRIM(s.s_phone)) AS SupplierInfo,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_phone,
        CONCAT(c.c_name, ' from ', c.c_address) AS CustomerDetails,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_address, c.c_phone
    HAVING 
        SUM(o.o_totalprice) > 1000
)
SELECT 
    r.r_name AS Region,
    rs.SupplierInfo,
    h.CustomerDetails,
    h.TotalSpent,
    SUBSTRING(r.r_comment, LENGTH(r.r_comment) - 49, 50) AS RegionCommentSnippet
FROM 
    RankedSuppliers rs
JOIN 
    nation n ON n.n_nationkey = (SELECT n_nationkey FROM supplier s WHERE s.s_suppkey = rs.s_suppkey)
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
JOIN 
    HighValueCustomers h ON h.c_custkey = (SELECT o.o_custkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_suppkey = rs.s_suppkey LIMIT 1)
WHERE 
    rs.rank <= 5
ORDER BY 
    r.r_name, h.TotalSpent DESC;
