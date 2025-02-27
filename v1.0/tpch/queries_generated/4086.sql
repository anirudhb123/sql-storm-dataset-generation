WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
),
supplier_parts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 5000
),
customer_overview AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_order_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
nation_stats AS (
    SELECT 
        n.n_regionkey,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(coalesce(c.total_order_spent, 0)) AS total_spent
    FROM 
        nation n
    JOIN 
        customer_overview c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_regionkey, n.n_name
)
SELECT 
    n.n_name, 
    p.p_name,
    p.ps_availqty,
    p.total_supply_cost,
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    o.order_rank,
    CASE 
        WHEN total_order_spent IS NULL THEN 'No Orders'
        ELSE CAST(total_order_spent AS VARCHAR)
    END AS customer_spending,
    CASE 
        WHEN s.s_suppkey IS NULL THEN 'Supplier Not Available'
        ELSE s.s_name
    END AS supplier_name
FROM 
    nation_stats n
LEFT JOIN 
    supplier_parts p ON n.n_regionkey = p.s_suppkey
LEFT JOIN 
    ranked_orders o ON o.o_orderkey = (SELECT MAX(o2.o_orderkey) FROM ranked_orders o2 WHERE o2.o_orderdate <= DATE '2023-09-30')
ORDER BY 
    n.n_name, o.o_orderdate DESC, p.total_supply_cost DESC;
