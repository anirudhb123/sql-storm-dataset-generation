WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM
        part p
),
TopSuppliers AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey, ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
CustomerOrders AS (
    SELECT DISTINCT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(o.o_comment, '; ') AS comments
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
    WHERE
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
    GROUP BY
        c.c_custkey, c.c_name
    HAVING
        COUNT(o.o_orderkey) > 0
),
SupplierParts AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
    HAVING
        total_cost = (SELECT MAX(total_supplycost) FROM TopSuppliers)
)
SELECT 
    R.p_partkey, 
    R.p_name,
    R.p_retailprice,
    C.c_custkey,
    C.c_name,
    C.order_count,
    C.total_spent,
    S.s_suppkey,
    S.s_name,
    S.part_count,
    S.total_cost
FROM 
    RankedParts R
FULL OUTER JOIN 
    CustomerOrders C ON R.price_rank = (SELECT MIN(price_rank) FROM RankedParts WHERE p_retailprice < 100 AND p_partkey IS NOT NULL)
LEFT JOIN 
    SupplierParts S ON R.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
WHERE
    COALESCE(C.total_spent, 0) BETWEEN 1000 AND 5000
    AND COALESCE(S.total_cost, 0) > 0
ORDER BY 
    R.p_retailprice DESC, 
    C.total_spent ASC, 
    S.s_name DESC;
