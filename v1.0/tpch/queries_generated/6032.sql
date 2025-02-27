WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS supplier_nation,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name AS customer_name,
        n.n_name AS customer_nation
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),
OrderLineSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS total_items
    FROM lineitem l
    GROUP BY l.l_orderkey
),
FinalReport AS (
    SELECT 
        ho.customer_name,
        ho.customer_nation,
        ol.total_revenue,
        ol.total_items,
        rs.s_name AS top_supplier,
        rs.rank AS supplier_rank
    FROM HighValueOrders ho
    JOIN OrderLineSummary ol ON ho.o_orderkey = ol.l_orderkey
    JOIN RankedSuppliers rs ON rs.rank = 1
)
SELECT 
    customer_name,
    customer_nation,
    total_revenue,
    total_items,
    top_supplier,
    supplier_rank
FROM FinalReport
ORDER BY total_revenue DESC;
