WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
),
FrequentCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
    HAVING
        COUNT(o.o_orderkey) > (
            SELECT
                AVG(order_count)
            FROM
                (SELECT COUNT(o2.o_orderkey) AS order_count
                 FROM orders o2
                 GROUP BY o2.o_custkey) AS subquery
        )
),
OrderSummary AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY
        o.o_orderkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT f.c_custkey) AS frequent_customer_count,
    MAX(os.total_revenue) AS max_order_revenue,
    STRING_AGG(DISTINCT CASE WHEN rs.supplier_rank = 1 THEN rs.s_name ELSE NULL END, ', ') AS top_suppliers
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
LEFT JOIN 
    FrequentCustomers f ON f.c_custkey = s.s_nationkey
LEFT JOIN 
    OrderSummary os ON os.o_orderkey IN (
        SELECT o.o_orderkey FROM orders o
        WHERE o.o_orderstatus = 'O' AND o.o_custkey IN (SELECT c.c_custkey FROM FrequentCustomers c)
    )
WHERE 
    (rs.supplier_rank IS NULL OR rs.supplier_rank <= 3)
AND
    (f.order_count IS NOT NULL OR f.order_count > 0)
GROUP BY 
    r.r_name
ORDER BY 
    region_name ASC;
