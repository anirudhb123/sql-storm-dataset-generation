WITH RECURSIVE TotalCost AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_cost
    FROM lineitem
    WHERE l_returnflag = 'N'
    GROUP BY l_orderkey
),
CustomerTotals AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(tc.total_cost) AS customer_total_cost
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN TotalCost tc ON o.o_orderkey = tc.l_orderkey
    GROUP BY c.c_custkey
),
SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_costs
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
)
SELECT 
    ct.c_custkey,
    ct.order_count,
    ct.customer_total_cost,
    rs.s_name,
    rs.s_acctbal,
    CASE 
        WHEN ct.customer_total_cost IS NULL THEN 'No Orders'
        WHEN ct.customer_total_cost > 10000 THEN 'High Value'
        ELSE 'Regular'
    END AS customer_value_category
FROM CustomerTotals ct
FULL OUTER JOIN RankedSuppliers rs ON ct.c_custkey = (SELECT c_nationkey FROM customer WHERE c_custkey = ct.c_custkey)
WHERE rs.supplier_rank <= 10 
ORDER BY ct.customer_total_cost DESC NULLS LAST, rs.s_name;
