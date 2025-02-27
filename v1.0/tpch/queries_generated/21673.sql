WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        COUNT(DISTINCT ps.ps_partkey) AS parts_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM RankedSuppliers s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY s.s_suppkey
),
FinalResult AS (
    SELECT 
        c.c_name,
        COALESCE(RS.supp_name, 'Unknown') AS supplier_name,
        COALESCE(HP.total_cost, 0) AS high_value_part_cost,
        COALESCE(SP.total_revenue, 0) AS supplier_revenue,
        COALESCE(CO.order_count, 0) AS customer_order_count,
        COALESCE(CO.total_spent, 0) AS customer_total_spent
    FROM CustomerOrders CO
    LEFT JOIN HighValueParts HP ON CO.customer_order_count > 5
    LEFT JOIN SupplierParts SP ON HP.ps_partkey = SP.parts_count
    LEFT JOIN RankedSuppliers RS ON SP.s_suppkey = RS.s_suppkey AND RS.rnk = 1
)
SELECT *
FROM FinalResult
WHERE customer_total_spent > 1000 OR supplier_revenue > 1000
ORDER BY customer_total_spent DESC, supplier_revenue ASC
LIMIT 50;
