WITH RegionalSupplierCost AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name, r.r_name
),
HighCostSuppliers AS (
    SELECT 
        s.s_name, 
        s.s_acctbal, 
        n.n_name,
        r.r_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > (
            SELECT 
                AVG(s2.s_acctbal) 
            FROM 
                supplier s2
            WHERE 
                s2.s_acctbal IS NOT NULL
        )
),
OrderLineData AS (
    SELECT 
        o.o_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_shipdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_linenumber) AS line_number
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
),
TopRevenueOrders AS (
    SELECT 
        ord.o_orderkey,
        SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS revenue
    FROM 
        OrderLineData ol
    JOIN 
        orders ord ON ol.o_orderkey = ord.o_orderkey
    GROUP BY 
        ord.o_orderkey
    HAVING 
        SUM(ol.l_extendedprice * (1 - ol.l_discount)) > 10000
)
SELECT 
    rsc.nation_name,
    rsc.region_name,
    SUM(tr.revenue) AS total_revenue,
    COUNT(DISTINCT hcs.s_name) AS high_cost_suppliers_count,
    EXTRACT(YEAR FROM MAX(ol.l_shipdate)) AS last_shipping_year,
    COALESCE(SUM(tr.revenue) FILTER (WHERE ol.l_shipdate > CURRENT_DATE - INTERVAL '1 year'), 0) AS revenue_last_year,
    (SELECT COUNT(DISTINCT c.c_custkey)
     FROM customer c
     WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
     ) AS active_customers
FROM 
    RegionalSupplierCost rsc
LEFT JOIN 
    TopRevenueOrders tr ON rsc.region_name = rsc.region_name
LEFT JOIN 
    HighCostSuppliers hcs ON hcs.n_name = rsc.nation_name
LEFT JOIN 
    lineitem ol ON ol.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
GROUP BY 
    rsc.nation_name, rsc.region_name
ORDER BY 
    total_revenue DESC
LIMIT 
    10;
