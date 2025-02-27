WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.s_acctbal, 
        n.n_name
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_suppkey = n.n_nationkey
    WHERE rs.rn <= 3
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT li.l_orderkey) AS order_count
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderdate >= DATEADD(year, -1, CURRENT_DATE)
    GROUP BY o.o_orderkey
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    COALESCE(SUM(ps.ps_availqty), 0) AS total_available_quantity,
    MAX(CASE WHEN ts.s_acctbal > 500 THEN 'High Balance' ELSE 'Low Balance' END) AS supplier_balance_category,
    AVG(od.total_revenue) AS avg_order_revenue
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
LEFT JOIN OrderDetails od ON ps.ps_partkey = od.o_orderkey
GROUP BY p.p_partkey, p.p_name
HAVING SUM(ps.ps_availqty) > 0
ORDER BY total_available_quantity DESC, p.p_name;
