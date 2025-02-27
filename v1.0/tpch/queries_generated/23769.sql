WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM
        supplier s
),
FilteredParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_size,
        p.p_retailprice,
        SUM(ps.ps_availqty) OVER (PARTITION BY p.p_partkey) AS total_avail_qty,
        CASE WHEN p.p_size BETWEEN 1 AND 20 THEN 'Small'
             WHEN p.p_size BETWEEN 21 AND 50 THEN 'Medium'
             WHEN p.p_size > 50 THEN 'Large'
             ELSE 'Undefined' END AS size_category
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE
        ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
),
EligibleCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CUME_DIST() OVER (ORDER BY c.c_acctbal DESC) AS cust_rank
    FROM
        customer c
    WHERE
        c.c_acctbal IS NOT NULL
)
SELECT
    o.o_orderkey,
    o.o_totalprice,
    ns.n_name AS supplier_nation,
    fp.p_name AS part_name,
    RANK() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS order_rank
FROM
    orders o
LEFT JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN
    RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey AND rs.rnk = 1
LEFT JOIN
    FilteredParts fp ON l.l_partkey = fp.p_partkey
JOIN
    nation ns ON rs.s_nationkey = ns.n_nationkey
WHERE
    (o.o_orderstatus = 'O' OR o.o_orderstatus = 'P')
    AND (fp.total_avail_qty IS NOT NULL OR fp.size_category = 'Large')
    AND (EXISTS (SELECT 1 FROM EligibleCustomers ec WHERE ec.c_custkey = o.o_custkey AND ec.cust_rank <= 0.1))
ORDER BY
    o.o_orderdate DESC,
    order_rank ASC
LIMIT 100;
