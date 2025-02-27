WITH supplier_ranking AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
top_suppliers AS (
    SELECT 
        supplier_ranking.s_suppkey,
        supplier_ranking.s_name,
        supplier_ranking.total_cost
    FROM 
        supplier_ranking
    WHERE 
        supplier_ranking.rank <= 5
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    ts.s_name,
    os.o_orderdate,
    os.total_revenue,
    ts.total_cost
FROM 
    top_suppliers ts
JOIN 
    order_summary os ON ts.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate = os.o_orderdate)
    )
ORDER BY 
    ts.total_cost DESC, os.total_revenue DESC;
