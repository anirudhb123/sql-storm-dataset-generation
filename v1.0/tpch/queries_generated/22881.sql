WITH RECURSIVE salesman_stats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
nation_supplier AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
part_aggregation AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
order_statistics AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value,
        COUNT(l.l_linenumber) AS item_count,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    ss.c_name AS customer_name,
    ss.total_sales,
    ns.n_name AS nation_name,
    pa.total_avail_qty,
    pa.avg_supply_cost,
    os.net_value,
    os.item_count,
    os.last_ship_date,
    CASE 
        WHEN ss.sales_rank = 1 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_type
FROM 
    salesman_stats ss
JOIN 
    customer c ON ss.c_custkey = c.c_custkey
LEFT JOIN 
    nation_supplier ns ON c.c_nationkey = (
        SELECT n.n_nationkey
        FROM nation n
        WHERE n.n_name = (
            SELECT DISTINCT n2.n_name
            FROM nation n2
            JOIN supplier s ON n2.n_nationkey = s.s_nationkey
            LIMIT 1
        )
    )
LEFT JOIN 
    part_aggregation pa ON pa.p_partkey = (
        SELECT p.p_partkey
        FROM part p
        ORDER BY RANDOM() -- Obscure semantic corner case
        LIMIT 1
    )
LEFT JOIN 
    order_statistics os ON os.o_orderkey = (
        SELECT o2.o_orderkey
        FROM orders o2
        WHERE o2.o_orderstatus = 'O' AND o2.o_totalprice > 1000
        ORDER BY o2.o_orderdate DESC
        LIMIT 1
    )
WHERE 
    ss.total_sales > (SELECT AVG(total_sales) FROM salesman_stats) 
    AND ns.supplier_count IS NOT NULL
ORDER BY 
    ss.total_sales DESC, customer_name ASC;
