WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        s.s_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) 
        FROM supplier s2
        WHERE s2.s_nationkey = s.s_nationkey
    )
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate) AS order_rank
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(od.revenue) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(od.revenue) > (
        SELECT AVG(total_revenue) 
        FROM (
            SELECT SUM(od.revenue) AS total_revenue
            FROM customer c2
            JOIN orders o2 ON c2.c_custkey = o2.o_custkey
            JOIN OrderDetails od ON o2.o_orderkey = od.o_orderkey
            GROUP BY c2.c_custkey
        ) AS subquery
    )
)
SELECT 
    c.c_name,
    sd.s_name,
    sd.nation_name,
    sd.s_acctbal,
    CASE 
        WHEN c.c_name IS NULL THEN 'Unknown Customer'
        ELSE c.c_name
    END AS formatted_customer_name,
    COALESCE(od.revenue, 0) AS total_revenue
FROM SupplierDetails sd
FULL OUTER JOIN TopCustomers c ON sd.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey IN (
        SELECT l.l_partkey
        FROM lineitem l
        WHERE l.l_orderkey IN (
            SELECT o.o_orderkey
            FROM orders o
            WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
        )
    )
)
LEFT JOIN OrderDetails od ON c.c_custkey = (
    SELECT o.o_custkey
    FROM orders o
    WHERE o.o_orderkey IN (
        SELECT od.o_orderkey
        FROM OrderDetails od
    )
)
ORDER BY sd.s_name, c.total_revenue DESC;
