WITH region_summary AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance,
        STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', s.s_address, ')'), ', ') AS supplier_list
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
),
customer_orders AS (
    SELECT 
        c.c_name AS customer_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        STRING_AGG(DISTINCT CONCAT(p.p_name, ' (Qty: ', l.l_quantity, ', Price: ', l.l_extendedprice, ')'), '; ') AS lineitem_details
    FROM 
        lineitem l
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    GROUP BY 
        l.l_orderkey
)
SELECT 
    rs.region_name,
    rs.nation_count,
    rs.total_supplier_balance,
    rs.supplier_list,
    co.customer_name,
    co.order_count,
    co.total_spent,
    co.last_order_date,
    ls.lineitem_details
FROM 
    region_summary rs
JOIN 
    customer_orders co ON rs.nation_count > 0
JOIN 
    lineitem_summary ls ON ls.l_orderkey IN (SELECT o.o_orderkey FROM orders o)
ORDER BY 
    rs.region_name, co.total_spent DESC;
