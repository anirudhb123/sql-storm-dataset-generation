
WITH RECURSIVE price_over_time AS (
    SELECT 
        o.o_orderkey,
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        l.l_returnflag,
        l.l_linestatus,
        (l.l_extendedprice * (1 - l.l_discount)) AS net_price,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_shipdate) AS ship_order
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
), 
supplier_stats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS supply_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
nation_totals AS (
    SELECT 
        n.n_nationkey,
        SUM(ss.total_supply_cost) AS nation_supply_cost,
        COUNT(DISTINCT c.c_custkey) AS nation_customer_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        supplier_stats ss ON s.s_suppkey = ss.s_suppkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    r.r_regionkey,
    r.r_name,
    n.n_name,
    nt.nation_supply_cost,
    nt.nation_customer_count,
    CASE 
        WHEN nt.nation_supply_cost IS NULL THEN 'No Supply Cost'
        ELSE 'Supply Cost Available'
    END AS supply_cost_status,
    COALESCE((SELECT AVG(net_price) FROM price_over_time WHERE l_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_type LIKE 'Special%')), 0) AS avg_net_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(o.o_orderdate) AS last_order_date
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    nation_totals nt ON n.n_nationkey = nt.n_nationkey
LEFT JOIN 
    orders o ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
GROUP BY 
    r.r_regionkey, r.r_name, n.n_name, nt.nation_supply_cost, nt.nation_customer_count
HAVING 
    MAX(o.o_orderdate) >= DATE '1997-01-01' OR nt.nation_customer_count > 10
ORDER BY 
    nt.nation_supply_cost DESC NULLS LAST, n.n_name ASC;
