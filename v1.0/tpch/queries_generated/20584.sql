WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
), 
HighCapSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM RankedSuppliers rs
    JOIN partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    WHERE rs.rn <= 5
    GROUP BY rs.s_suppkey, rs.s_name
), 
CustomerOrderData AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), 
SalesSummary AS (
    SELECT 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_order_value
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag = 'N'
)
SELECT 
    rs.s_name AS supplier_name,
    cs.c_name AS customer_name,
    os.total_sales,
    os.avg_order_value,
    cs.order_count,
    cs.total_spent
FROM HighCapSuppliers rs
FULL OUTER JOIN CustomerOrderData cs ON rs.s_suppkey = cs.c_custkey
FULL OUTER JOIN SalesSummary os ON cs.c_custkey IS NOT NULL OR rs.s_suppkey IS NOT NULL
WHERE (rs.s_name IS NOT NULL OR cs.customer_name IS NOT NULL)
AND (cs.total_spent > 1000 OR os.avg_order_value IS NULL)
ORDER BY os.total_sales DESC, cs.order_count DESC NULLS LAST;
