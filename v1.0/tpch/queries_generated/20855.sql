WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
high_value_customers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
),
supply_chain AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(l.l_extendedprice) AS avg_price
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
final_report AS (
    SELECT 
        ho.o_orderkey,
        ho.o_totalprice,
        ho.o_orderstatus,
        hc.total_spent,
        sd.total_supplycost,
        sc.avg_price
    FROM 
        ranked_orders ho
    LEFT JOIN 
        high_value_customers hc ON ho.o_orderkey = hc.c_custkey
    LEFT JOIN 
        supplier_details sd ON ho.o_orderstatus = sd.s_suppkey
    LEFT JOIN 
        supply_chain sc ON hc.total_spent = sc.supplier_count
    WHERE 
        ho.rnk = 1
        AND (ho.o_totalprice IS NOT NULL OR ho.o_totalprice < 10000 AND ho.o_orderstatus = 'O')
)
SELECT 
    f.o_orderkey, 
    f.o_totalprice, 
    f.o_orderstatus, 
    COALESCE(f.total_spent, 0) AS total_spent,
    COALESCE(f.total_supplycost, 0) AS total_supplycost,
    CASE 
        WHEN f.avg_price IS NULL THEN 'N/A' 
        ELSE CAST(f.avg_price AS VARCHAR) 
    END AS avg_price
FROM 
    final_report f
ORDER BY 
    f.o_totalprice DESC, 
    f.o_orderstatus;
