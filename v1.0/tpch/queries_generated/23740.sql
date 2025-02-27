WITH RankedSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) as rn
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerHighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
DistinctNations AS (
    SELECT DISTINCT 
        n.n_nationkey,
        n.n_name
    FROM 
        nation n 
    WHERE 
        n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'R%')
),
FinalOutput AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        rs.s_name AS supplier_name,
        chvo.o_totalprice,
        chvo.c_name AS customer_name
    FROM 
        part p
    LEFT OUTER JOIN RankedSuppliers rs ON p.p_partkey = rs.ps_partkey AND rs.rn = 1
    LEFT JOIN CustomerHighValueOrders chvo ON chvo.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey 
        AND l.l_quantity > 10
    )
    WHERE 
        (p.p_retailprice / 2) < COALESCE(chvo.o_totalprice, 0) 
        AND EXISTS (
            SELECT 1 
            FROM DistinctNations dn 
            WHERE dn.n_nationkey = (SELECT s.n_nationkey FROM supplier s WHERE s.s_suppkey = rs.ps_suppkey)
        )
)
SELECT 
    p_partkey,
    p_name,
    supplier_name,
    o_totalprice,
    customer_name
FROM 
    FinalOutput
ORDER BY 
    o_totalprice DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
