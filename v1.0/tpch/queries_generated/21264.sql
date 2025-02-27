WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
TotalRevenue AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
HighRevenueOrders AS (
    SELECT 
        tr.o_orderkey,
        ROW_NUMBER() OVER (ORDER BY tr.total_revenue DESC) AS order_rank
    FROM TotalRevenue tr
),
SupplierDetails AS (
    SELECT 
        ns.n_name,
        rs.s_name,
        rs.s_acctbal,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_qty
    FROM RankedSuppliers rs
    JOIN nation ns ON rs.s_nationkey = ns.n_nationkey
    LEFT JOIN partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    GROUP BY ns.n_name, rs.s_suppkey, rs.s_name, rs.s_acctbal
)
SELECT 
    sd.n_name,
    sd.s_name,
    sd.s_acctbal,
    HRO.order_rank,
    COALESCE(sd.total_qty, 0) AS total_quantity,
    CASE 
        WHEN HRO.order_rank IS NOT NULL THEN 'High Revenue'
        ELSE 'Regular'
    END AS revenue_category
FROM SupplierDetails sd
LEFT JOIN HighRevenueOrders HRO ON sd.s_suppkey = HRO.o_orderkey
WHERE sd.s_acctbal BETWEEN 1000 AND 10000
ORDER BY sd.n_name, sd.s_acctbal DESC, revenue_category;
