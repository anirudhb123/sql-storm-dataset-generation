WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY YEAR(o.o_orderdate) ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus <> 'F'
),

nation_supplier AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name, s.s_suppkey, s.s_name
),

order_lineitems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(*) FILTER (WHERE l.l_returnflag = 'R') AS return_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)

SELECT 
    r.o_orderkey,
    r.o_totalprice AS order_total,
    ns.n_name AS supplier_nation,
    COALESCE(ol.net_revenue, 0) AS total_revenue,
    CASE 
        WHEN ns.total_supply_cost IS NULL THEN 'No supplier'
        ELSE 'Supplier available'
    END AS supplier_status,
    COUNT(DISTINCT l.l_suppkey) FILTER (WHERE l.l_returnflag = 'N') AS valid_suppliers,
    COUNT(DISTINCT n.n_nationkey) OVER () AS total_nations_served
FROM 
    ranked_orders r
LEFT JOIN 
    orders o ON r.o_orderkey = o.o_orderkey
LEFT JOIN 
    order_lineitems ol ON o.o_orderkey = ol.l_orderkey
LEFT JOIN 
    nation_supplier ns ON ol.l_orderkey = ns.s_suppkey
LEFT JOIN 
    lineitem l ON ol.l_orderkey = l.l_orderkey
WHERE 
    (r.price_rank <= 5 OR r.o_totalprice < 1000) 
    AND r.o_orderdate >= (SELECT MAX(o_orderdate) FROM orders WHERE o_orderstatus = 'O')
    AND (r.o_totalprice IS NOT NULL OR ns.total_supply_cost IS NOT NULL)
GROUP BY 
    r.o_orderkey, r.o_totalprice, ns.n_name, ol.net_revenue
HAVING 
    total_revenue > 1000 OR supplier_status = 'No supplier'
ORDER BY 
    r.o_totalprice DESC NULLS LAST;
