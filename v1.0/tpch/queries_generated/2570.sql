WITH SupPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        COUNT(l.l_orderkey) AS line_item_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
NationWithTotalSales AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        SUM(os.order_total) AS total_sales
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        OrderSummary os ON c.c_custkey = os.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COALESCE(SUM(nt.total_sales), 0) AS total_sales,
    COALESCE(p.total_available_quantity, 0) AS total_available_quantity,
    SUM(CASE 
            WHEN p.total_supply_cost IS NOT NULL THEN p.total_supply_cost
            ELSE NULL 
        END) AS total_supply_cost,
    COUNT(DISTINCT os.o_orderkey) AS total_orders
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    NationWithTotalSales nt ON n.n_nationkey = nt.n_nationkey
LEFT JOIN 
    SupPartInfo p ON n.n_nationkey = (SELECT n2.n_nationkey FROM nation n2 WHERE n2.n_nationkey = p.ps_partkey)
LEFT JOIN 
    OrderSummary os ON os.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    total_sales DESC, total_available_quantity DESC;
