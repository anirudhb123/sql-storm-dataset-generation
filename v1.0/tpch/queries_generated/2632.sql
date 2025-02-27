WITH RankedSales AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY
        s.s_suppkey, s.s_name
),
CustomerNation AS (
    SELECT
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        c.c_acctbal
    FROM
        customer c
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
OrderSummary AS (
    SELECT
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM
        orders o
    LEFT JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderstatus, o.o_orderdate
)
SELECT
    cn.nation_name,
    COUNT(DISTINCT cn.c_custkey) AS customer_count,
    SUM(COALESCE(rs.total_sales, 0)) AS total_supplier_sales,
    AVG(os.lineitem_count) AS average_lineitem_per_order
FROM
    CustomerNation cn
LEFT JOIN
    RankedSales rs ON cn.c_custkey = (SELECT c.c_custkey 
                                       FROM customer c 
                                       WHERE c.c_nationkey = cn.c_nationkey 
                                       ORDER BY c.c_acctbal DESC
                                       LIMIT 1)
LEFT JOIN
    OrderSummary os ON os.o_orderstatus = 'F'
GROUP BY
    cn.nation_name
HAVING
    SUM(COALESCE(rs.total_sales, 0)) > 100000
ORDER BY
    customer_count DESC, total_supplier_sales DESC;
