WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 
            (SELECT AVG(s1.s_acctbal) FROM supplier s1 WHERE s1.s_nationkey = s.s_nationkey)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate > DATEADD(month, -12, GETDATE())
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        COALESCE(MAX(RS.supplier_rank), 0) AS max_rank
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        RankedSuppliers RS ON ps.ps_suppkey = RS.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
)
SELECT 
    R.r_name,
    C.c_name,
    SUM(P.max_rank) AS total_rank,
    COUNT(DISTINCT P.p_partkey) AS part_count,
    STRING_AGG(DISTINCT P.p_name, ', ') AS parts_list,
    AVG(C.total_spent) AS avg_customer_spending
FROM 
    region R
JOIN 
    nation N ON R.r_regionkey = N.n_regionkey
JOIN 
    supplier S ON N.n_nationkey = S.s_nationkey
JOIN 
    PartSupplierInfo P ON S.s_suppkey = P.ps_suppkey
JOIN 
    CustomerOrders C ON C.c_custkey = S.s_suppkey 
GROUP BY 
    R.r_name, C.c_name
HAVING 
    SUM(P.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    total_rank DESC, part_count ASC;
