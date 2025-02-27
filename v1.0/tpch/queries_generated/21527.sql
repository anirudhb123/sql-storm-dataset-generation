WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM
        supplier s
),
PartDetails AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE
            WHEN p.p_size IS NULL THEN 'Undefined Size'
            ELSE CONCAT('Size: ', p.p_size)
        END AS size_description
    FROM
        part p
    WHERE
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey
    HAVING
        SUM(o.o_totalprice) > 1000
),
LineItemDetails AS (
    SELECT
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_price_after_discount,
        CASE 
            WHEN l.l_returnflag = 'Y' THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM
        lineitem l
    GROUP BY
        l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_returnflag
)
SELECT
    c.c_name,
    c.c_acctbal,
    COUNT(o.o_orderkey) AS number_of_orders,
    MAX(o.o_orderdate) AS last_order_date,
    p.p_name,
    pd.size_description,
    ss.s_name AS supplier_name,
    r.r_name AS region_name
FROM
    CustomerOrders co
JOIN
    customer c ON co.c_custkey = c.c_custkey
LEFT JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    PartDetails pd ON pd.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
JOIN
    RankedSuppliers ss ON pd.p_partkey = ss.s_suppkey
LEFT JOIN
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    r.r_name NOT IN ('EUROPE', 'ASIA') 
    AND COALESCE(c.c_acctbal, 0) > 500
GROUP BY
    c.c_name, c.c_acctbal, p.p_name, pd.size_description, ss.s_name, r.r_name
HAVING
    COUNT(o.o_orderkey) > 5 
ORDER BY
    total_spent DESC NULLS LAST;
