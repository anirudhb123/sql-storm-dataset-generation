WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (
            SELECT AVG(o1.o_totalprice)
            FROM orders o1
            WHERE o1.o_orderdate >= DATEADD(month, -6, GETDATE())
        )
), 
filtered_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(ps.ps_availqty, 0) AS available_quantity
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice < 100.00
        AND p.p_comment NOT LIKE '%fragile%'
), 
supply_stats AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
), 
orders_summary AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        CASE 
            WHEN ro.o_orderstatus = 'O' THEN 'Open'
            ELSE 'Completed'
        END AS order_status,
        count(li.l_orderkey) OVER (PARTITION BY ro.o_orderkey) AS line_item_count
    FROM 
        ranked_orders ro
    LEFT JOIN 
        lineitem li ON ro.o_orderkey = li.l_orderkey
    WHERE 
        ro.order_rank <= 10
)

SELECT 
    p.p_name,
    p.p_retailprice,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    os.order_total_price,
    os.line_item_count,
    CASE 
        WHEN os.o_orderkey IS NOT NULL THEN 'Exists'
        ELSE 'Does Not Exist'
    END AS order_existence,
    r.r_name
FROM 
    filtered_parts p
LEFT JOIN 
    supply_stats ss ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 10)
LEFT JOIN 
    orders_summary os ON p.p_partkey = os.o_orderkey
LEFT JOIN 
    nation n ON ss.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.available_quantity > (
        SELECT AVG(available_quantity)
        FROM filtered_parts
    )
ORDER BY 
    p.p_retailprice ASC, 
    os.line_item_count DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
