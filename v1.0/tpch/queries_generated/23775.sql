WITH RECURSIVE region_order_totals AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(o.o_totalprice) AS total_order_price,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
part_supplier_costs AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
top_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING COUNT(ps.ps_partkey) > 10
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderstatus,
        CASE 
            WHEN o.o_orderstatus = 'O' THEN 'Open Order'
            ELSE 'Closed Order'
        END AS order_status_description,
        LAG(o.o_totalprice) OVER (ORDER BY o.o_orderdate) AS previous_order_price
    FROM 
        orders o
),
combined_summary AS (
    SELECT 
        r.r_name,
        r.total_order_price,
        r.order_count,
        p.p_name,
        p.total_supplycost,
        ts.s_name,
        os.o_orderkey,
        os.order_totalprice,
        os.order_status_description
    FROM 
        region_order_totals r
    JOIN 
        part_supplier_costs p ON r.order_count > 5
    LEFT JOIN 
        top_suppliers ts ON TRUE
    LEFT JOIN 
        order_summary os ON os.o_orderkey % 2 = 0
)

SELECT 
    r_name,
    total_order_price,
    order_count,
    p_name,
    total_supplycost,
    s_name,
    COUNT(o_orderkey) AS order_count_total,
    COALESCE(MAX(o_totalprice), 0) AS max_order_price,
    NULLIF(SUM(total_supplycost), 0) AS supplycost_sum
FROM 
    combined_summary
WHERE 
    total_order_price IS NOT NULL
GROUP BY 
    r_name, total_order_price, order_count, p_name, total_supplycost, s_name
HAVING 
    SUM(total_supplycost) > 1000.00 AND 
    AVG(total_order_price) <= (SELECT AVG(o_totalprice) FROM orders)
ORDER BY 
    r_name DESC, order_count
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;
