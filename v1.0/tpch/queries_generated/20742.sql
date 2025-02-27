WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM
        supplier s
),
HighValueCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'Unknown'
            WHEN c.c_acctbal >= 10000 THEN 'High'
            ELSE 'Low'
        END AS cust_value,
        c.c_nationkey
    FROM
        customer c
    WHERE
        c.c_mktsegment IN ('BUILDING', 'AUTO')
),
NationRegion AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY n.n_name) AS nation_rank
    FROM
        nation n
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
),
OrderLines AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_price,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        l.l_returnflag = 'R'
    GROUP BY
        o.o_orderkey
)

SELECT
    n.n_name AS nation,
    r.region_name,
    s.s_name AS supplier_name,
    COALESCE(c.c_name, 'No Customer') AS customer_name,
    o.total_line_item_price,
    h.cust_value,
    ps.ps_availqty,
    (SELECT COUNT(*) 
     FROM partsupp ps 
     WHERE ps.ps_partkey IN (SELECT p.p_partkey 
                             FROM part p 
                             WHERE p.p_size > 10 AND p.p_retailprice BETWEEN 100.00 AND 500.00)) AS part_count_from_part_table
FROM 
    RankedSuppliers s
LEFT JOIN 
    NationRegion n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    HighValueCustomers h ON n.n_nationkey = h.c_nationkey
LEFT JOIN 
    OrderLines o ON o.o_orderkey = (SELECT o2.o_orderkey 
                                      FROM orders o2 
                                      WHERE o2.o_custkey = h.c_custkey 
                                      ORDER BY o2.o_orderdate DESC 
                                      LIMIT 1)
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey 
WHERE
    (n.nation_rank <= 5 OR s.rank <= 3)
AND
    (o.total_line_item_price > 1000 OR h.cust_value = 'High')
ORDER BY
    n.n_name, s.s_name, total_line_item_price DESC
FETCH FIRST 100 ROWS ONLY;
