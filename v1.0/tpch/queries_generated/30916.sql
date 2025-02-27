WITH RECURSIVE part_supplier_costs AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        1 AS hierarchy_level
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey

    UNION ALL

    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) + p.total_supply_cost AS total_supply_cost,
        hierarchy_level + 1
    FROM 
        partsupp ps
    JOIN part_supplier_costs p ON ps.ps_partkey = p.ps_partkey
    GROUP BY 
        ps.ps_partkey, p.total_supply_cost, hierarchy_level
),

customer_order_summary AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),

nations_with_customers AS (
    SELECT 
        n.n_name,
        SUM(cs.total_spent) AS total_nation_spending,
        COUNT(cs.c_custkey) AS total_customers
    FROM 
        nation n
    JOIN 
        customer_order_summary cs ON n.n_nationkey = cs.c_custkey
    GROUP BY 
        n.n_name
),

supplier_part_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        p.p_retailprice,
        COALESCE(NULLIF(p.p_comment, ''), 'No comment') AS normalized_comment
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 500.00
),

final_report AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(sp.p_retailprice) AS total_value_of_parts,
        COUNT(DISTINCT sp.s_name) AS unique_supplier_count,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(sp.p_retailprice) DESC) AS rn
    FROM 
        nations_with_customers n
    JOIN 
        supplier_part_details sp ON n.n_nationkey = sp.s_suppkey
    GROUP BY 
        n.n_name
)

SELECT 
    fr.nation_name,
    fr.total_value_of_parts,
    fr.unique_supplier_count
FROM 
    final_report fr
WHERE 
    fr.rn <= 3
ORDER BY 
    fr.total_value_of_parts DESC;

