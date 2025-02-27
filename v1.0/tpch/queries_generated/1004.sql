WITH SupplierPerformance AS (
    SELECT 
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_by_supply,
        AVG(c.c_acctbal) AS avg_customer_balance
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE
        l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate <= DATE '2023-12-31'
    GROUP BY
        s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        s_name, nation_name, total_supply_value, total_orders,
        avg_customer_balance,
        ROW_NUMBER() OVER (ORDER BY total_supply_value DESC) AS overall_rank
    FROM 
        SupplierPerformance
    WHERE 
        total_orders > 5
)
SELECT 
    t.s_name,
    t.nation_name,
    t.total_supply_value,
    t.total_orders,
    t.avg_customer_balance,
    t.overall_rank,
    CASE 
        WHEN t.total_supply_value IS NULL THEN 'No Supply'
        WHEN t.avg_customer_balance > 5000 THEN 'High Value'
        ELSE 'Standard Value'
    END AS supplier_status
FROM 
    TopSuppliers t
WHERE 
    t.overall_rank <= 10 
ORDER BY 
    t.total_supply_value DESC;

WITH RecursiveDates AS (
    SELECT 
        DATE '2023-01-01' AS report_date
    UNION ALL
    SELECT 
        report_date + INTERVAL '1' DAY
    FROM 
        RecursiveDates
    WHERE 
        report_date + INTERVAL '1' DAY <= DATE '2023-12-31'
)
SELECT COUNT(*) AS total_days
FROM RecursiveDates;
