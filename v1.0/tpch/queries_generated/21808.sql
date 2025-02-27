WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_price
    FROM
        orders o
),
CustNation AS (
    SELECT
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY c.c_acctbal DESC) AS rng
    FROM
        customer c
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE
        c.c_acctbal IS NOT NULL AND c.c_acctbal > (
            SELECT AVG(c2.c_acctbal)
            FROM customer c2
            WHERE c2.c_mktsegment = c.c_mktsegment
        )
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(NULLIF(s.s_comment, ''), 'No Comment') AS supplier_comment
    FROM
        supplier s
    WHERE
        s.s_acctbal > 0
),
DiscountedLineitems AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_discounted_price,
        l.l_tax,
        l.l_returnflag
    FROM
        lineitem l
    WHERE
        l.l_discount BETWEEN 0 AND 0.1
    GROUP BY
        l.l_orderkey, l.l_returnflag
)
SELECT
    a.o_orderkey,
    a.o_totalprice,
    b.c_name,
    c.nation_name,
    d.total_discounted_price,
    SUM(CASE WHEN d.l_returnflag = 'Y' THEN d.total_discounted_price ELSE 0 END) AS return_total,
    MAX(b.rng) AS max_rng,
    COUNT(DISTINCT e.s_suppkey) AS unique_suppliers
FROM
    RankedOrders a
JOIN
    CustNation b ON a.o_custkey = b.c_custkey
LEFT JOIN
    nation c ON b.nation_name = c.n_name
JOIN
    DiscountedLineitems d ON a.o_orderkey = d.l_orderkey
LEFT JOIN
    partsupp e ON e.ps_partkey = (
        SELECT ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_availqty IS NOT NULL 
        ORDER BY ps.ps_supplycost 
        LIMIT 1
    )
WHERE
    a.rank_price <= 10 AND
    d.total_discounted_price IS NOT NULL
GROUP BY
    a.o_orderkey, a.o_totalprice, b.c_name, c.nation_name, d.l_orderkey
ORDER BY
    a.o_totalprice DESC;
