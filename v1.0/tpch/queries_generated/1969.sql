WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rn
    FROM
        supplier s
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderstatus = 'O'
    GROUP BY
        c.c_custkey, c.c_name
),
QualifiedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING
        AVG(ps.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp)
),
FinalBenchmark AS (
    SELECT
        co.c_custkey,
        co.c_name,
        qp.p_partkey,
        qp.p_name,
        qp.p_retailprice,
        qp.avg_supply_cost,
        rs.s_name AS top_supplier
    FROM
        CustomerOrders co
    JOIN
        QualifiedParts qp ON co.order_count > 5
    LEFT JOIN
        RankedSuppliers rs ON rs.rn = 1 AND rs.s_suppkey IN 
            (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = qp.p_partkey)
)
SELECT
    fb.c_custkey,
    fb.c_name,
    fb.p_partkey,
    fb.p_name,
    fb.p_retailprice,
    fb.avg_supply_cost,
    fb.top_supplier
FROM
    FinalBenchmark fb
WHERE 
    fb.avg_supply_cost IS NOT NULL
ORDER BY
    fb.c_custkey, fb.p_partkey;
