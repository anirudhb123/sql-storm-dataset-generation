WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_supplykey) AS supplier_count,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
    GROUP BY
        o.o_orderkey, o.o_orderstatus
),
TopRevenueOrders AS (
    SELECT
        r.o_orderkey,
        r.total_revenue,
        s.s_name AS top_supplier,
        r.revenue_rank
    FROM
        RankedOrders r
    JOIN
        partsupp ps ON r.o_orderkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE
        r.revenue_rank <= 10
)
SELECT 
    o.o_orderkey,
    o.total_revenue,
    o.top_supplier,
    (SELECT COUNT(*) FROM customer c WHERE c.c_nationkey = s.s_nationkey) AS total_customers,
    (SELECT AVG(c.c_acctbal) FROM customer c WHERE c.c_nationkey = s.s_nationkey) AS avg_account_balance
FROM 
    TopRevenueOrders o
JOIN 
    supplier s ON o.top_supplier = s.s_name
ORDER BY 
    o.total_revenue DESC;
