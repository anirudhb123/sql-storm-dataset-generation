WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY ps.ps_supplycost DESC) AS rank_per_mfgr
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 10000
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
    GROUP BY 
        o.o_orderkey
)

SELECT 
    rp.p_name,
    rp.p_mfgr,
    ts.nation_name,
    od.total_revenue
FROM
    RankedParts rp
JOIN
    TopSuppliers ts ON rp.rank_per_mfgr = 1
JOIN
    OrderDetails od ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey)
WHERE
    rp.ps_supplycost < 50
ORDER BY 
    od.total_revenue DESC
LIMIT 10;