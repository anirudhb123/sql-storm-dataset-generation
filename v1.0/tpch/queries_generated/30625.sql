WITH RECURSIVE SupplierRank AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
CustomerOrderStats AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS total_orders, 
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS average_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), 
FilteredPart AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' 
        AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    COUNT(DISTINCT sr.s_suppkey) AS top_suppliers,
    AVG(cos.total_orders) AS avg_orders_per_customer,
    MAX(f.total_quantity_sold) AS max_quantity_sold_for_a_part
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierRank sr ON sr.rank <= 10
LEFT JOIN 
    CustomerOrderStats cos ON cos.c_custkey IS NOT NULL
LEFT JOIN 
    FilteredPart f ON f.p_partkey IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT n.n_nationkey) > 1
ORDER BY 
    nation_count DESC, 
    top_suppliers DESC;
