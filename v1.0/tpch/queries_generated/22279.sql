WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(NULLIF(p.p_comment, ''), 'No comment') AS adjusted_comment,
        (SELECT COUNT(*) 
         FROM partsupp ps 
         WHERE ps.ps_partkey = p.p_partkey) AS supplier_count
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 30 
        AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name 
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL AND 
        COUNT(o.o_orderkey) > 5
),
FinalOutput AS (
    SELECT 
        td.p_partkey,
        td.p_name,
        td.p_retailprice,
        ts.c_custkey,
        ts.c_name,
        ts.total_spent,
        rs.s_name,
        rs.rank
    FROM 
        PartDetails td
    LEFT JOIN 
        RankedSuppliers rs ON rs.rank = 1
    LEFT JOIN 
        TopCustomers ts ON ts.total_spent > 1000
    WHERE 
        EXISTS (SELECT 1 
                FROM lineitem li 
                WHERE li.l_partkey = td.p_partkey 
                  AND li.l_orderkey IN (SELECT o.o_orderkey 
                                        FROM orders o 
                                        WHERE o.o_orderstatus = 'F'))
)

SELECT 
    f.p_partkey,
    f.p_name,
    f.p_retailprice,
    f.c_custkey,
    f.c_name,
    COALESCE(f.total_spent, 0) AS total_spent,
    f.s_name,
    f.rank
FROM 
    FinalOutput f
ORDER BY 
    f.p_retailprice DESC, f.total_spent ASC
LIMIT 100 OFFSET 10;
