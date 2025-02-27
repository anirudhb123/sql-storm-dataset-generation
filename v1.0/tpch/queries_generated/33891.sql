WITH RECURSIVE sales_rank AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
ranked_suppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        DENSE_RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
high_value_customers AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    n.n_name,
    p.p_name,
    ss.total_supply_cost,
    hvc.total_spent,
    sr.total_sales
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    part p ON p.p_partkey IN (SELECT ps.ps_partkey FROM ranked_suppliers ps WHERE ps.supplier_rank = 1)
LEFT JOIN 
    ranked_suppliers ss ON p.p_partkey = ss.ps_partkey
LEFT JOIN 
    sales_rank sr ON sr.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
LEFT JOIN 
    high_value_customers hvc ON hvc.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal > 10000)
WHERE 
    r.r_name NOT LIKE '%East%'
    AND (ss.total_supply_cost IS NOT NULL OR hvc.total_spent IS NOT NULL)
ORDER BY 
    r.r_name, n.n_name;
