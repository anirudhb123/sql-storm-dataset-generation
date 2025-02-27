WITH cte_order_summary AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderstatus
),
cte_part_supply AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        MAX(ps.ps_supplycost) AS max_supply_cost
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey
),
cte_supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Not available' 
            ELSE CONCAT('Account balance: ', s.s_acctbal) 
        END AS account_status
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name IS NOT NULL
),
cte_combined AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name
    FROM 
        partsupp ps
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        ps.ps_partkey, s.s_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS number_of_customers,
    SUM(o.o_totalprice) AS total_order_value,
    SUM(ps.total_available_quantity) AS total_available_parts,
    AVG(cte.total_sales) AS average_sales_per_part,
    MAX(s.s_acctbal) AS max_supplier_balance
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    cte_combined ps ON ps.ps_partkey IN (SELECT ps_partkey FROM cte_part_supply)
LEFT JOIN 
    cte_supplier_info s ON ps.supplier_name = s.s_name
GROUP BY 
    r.r_name
HAVING 
    COUNT(c.c_custkey) > 0
ORDER BY 
    total_order_value DESC;
