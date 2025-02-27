WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
AvailableParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        l.l_returnflag,
        l.l_linestatus,
        l.l_shipdate,
        l.l_comment,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS rn
    FROM lineitem l
    WHERE l.l_discount BETWEEN 0.1 AND 0.3
)

SELECT 
    n.n_name,
    COALESCE(SUM(ali.total_available), 0) AS total_parts_available,
    COALESCE(SUM(hvc.total_spent), 0) AS total_revenue_from_high_value_customers,
    COUNT(DISTINCT rs.s_name) AS supplier_count,
    COUNT(DISTINCT fl.l_orderkey) AS processed_orders
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey AND rs.rank <= 5
LEFT JOIN AvailableParts ali ON rs.s_suppkey = ali.ps_partkey
LEFT JOIN HighValueCustomers hvc ON hvc.c_custkey IN (
    SELECT DISTINCT c.c_custkey 
    FROM customer c 
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
)
LEFT JOIN FilteredLineItems fl ON fl.l_orderkey IN (
    SELECT DISTINCT o.o_orderkey
    FROM orders o
    WHERE o.o_orderstatus = 'O'
)
WHERE r.r_name LIKE 'N%'
GROUP BY n.n_name
ORDER BY total_parts_available DESC, total_revenue_from_high_value_customers DESC;
