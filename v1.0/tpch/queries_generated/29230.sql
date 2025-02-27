WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        CONCAT('Supplier: ', s.s_name, ' | Balance: $', FORMAT(s.s_acctbal, 2)) AS SupplierDetails,
        ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS Rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 10000
), FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        SUBSTRING(p.p_comment, 1, 20) AS ShortComment,
        CHAR_LENGTH(p.p_comment) AS CommentLength
    FROM 
        part p
    WHERE 
        p.p_retailprice > 50
), OrdersWithDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalPrice,
        COUNT(l.l_orderkey) AS ItemCount,
        STRING_AGG(DISTINCT CONCAT(p.p_name, ' (Qty: ', l.l_quantity, ')'), '; ') AS ItemDetails
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        FilteredParts p ON l.l_partkey = p.p_partkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.Rank,
    r.SupplierDetails,
    o.o_orderkey,
    o.o_orderdate,
    o.TotalPrice,
    o.ItemCount,
    o.ItemDetails
FROM 
    RankedSuppliers r
JOIN 
    OrdersWithDetails o ON r.s_suppkey IN (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_partkey IN (
                SELECT p.p_partkey 
                FROM FilteredParts p
            )
    )
ORDER BY 
    r.Rank, o.TotalPrice DESC;
