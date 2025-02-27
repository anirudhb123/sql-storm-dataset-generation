WITH RECURSIVE PriceRanks AS (
    SELECT 
        ps_partkey,
        ps_suppkey,
        ps_supplycost,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS rank_order
    FROM 
        partsupp
),
AggregatedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS item_count,
        FIRST_VALUE(l.l_shipmode) OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS shipping_method
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
NullAndTotallyTrue AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        COUNT(DISTINCT CASE WHEN ps.ps_availqty = 0 THEN NULL END) AS zero_quantity_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    r.r_name,
    a.total_revenue, 
    s.s_name,
    n.n_name,
    p.p_name,
    COALESCE(zero_quantity_count, 0) AS zero_suppliers,
    CASE 
        WHEN a.item_count > 10 THEN 'High Volume'
        WHEN a.item_count BETWEEN 5 AND 10 THEN 'Medium Volume'
        ELSE 'Low Volume' 
    END AS order_volume_category
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierDetails s ON s.s_suppkey = (SELECT TOP 1 ps_suppkey FROM PriceRanks pr WHERE pr.rank_order = 1 AND pr.ps_partkey IN (SELECT p_partkey FROM part) ORDER BY pr.ps_supplycost DESC)
JOIN 
    AggregatedOrders a ON a.o_orderkey IN (SELECT o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
JOIN 
    NullAndTotallyTrue p ON p.p_partkey = (SELECT p_partkey FROM part WHERE p.p_name LIKE '%rubber%' ORDER BY p.p_partkey DESC LIMIT 1)
WHERE 
    r.r_name IS NOT NULL
ORDER BY 
    total_revenue DESC, 
    n.n_name ASC, 
    zero_suppliers DESC;
