WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_shippriority,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1995-01-01' AND
        o.o_orderdate < DATEADD(day, 1, CURRENT_DATE)
),
filtered_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name
    HAVING 
        AVG(ps.ps_supplycost) < (
            SELECT 
                AVG(ps_supplycost) 
            FROM 
                partsupp 
            WHERE 
                ps_partkey IN (
                    SELECT 
                        p.p_partkey 
                    FROM 
                        part p 
                    WHERE 
                        p.p_size BETWEEN 1 AND 10
                )
        )
),
order_line_details AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MAX(l.l_tax) AS max_tax 
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N' 
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    ol.total_revenue,
    fs.s_name AS supplier_name,
    CASE 
        WHEN ol.max_tax IS NULL THEN 'No Tax'
        ELSE 'Tax Applied'
    END AS tax_status
FROM 
    ranked_orders o 
LEFT JOIN 
    order_line_details ol ON o.o_orderkey = ol.l_orderkey
LEFT JOIN 
    filtered_suppliers fs ON EXISTS (
        SELECT 1
        FROM partsupp ps
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_mfgr LIKE 'Manufacturer%')
        AND ps.ps_suppkey = fs.s_suppkey
    )
WHERE 
    o.order_rank <= 10 AND 
    (o.o_shippriority > 0 OR fs.s_name IS NOT NULL)
ORDER BY 
    o.o_totalprice DESC, 
    ol.total_revenue DESC;
