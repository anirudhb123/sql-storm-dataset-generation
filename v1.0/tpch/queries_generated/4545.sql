WITH region_summary AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
high_value_customers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
combined_data AS (
    SELECT 
        r.r_name AS region_name,
        h.c_name AS high_value_customer,
        o.total_order_value,
        COALESCE(o.o_orderstatus, 'N/A') AS order_status
    FROM 
        region_summary r
    JOIN 
        high_value_customers h ON EXISTS (
            SELECT 1 
            FROM orders o 
            WHERE o.o_custkey = h.c_custkey 
            AND o.o_orderstatus = 'O'
        )
    LEFT JOIN 
        order_summary o ON o.o_orderkey = (
            SELECT MIN(o2.o_orderkey) 
            FROM orders o2 
            WHERE o2.o_custkey = h.c_custkey 
            AND o.o_orderstatus = 'O'
        )
)
SELECT 
    region_name,
    high_value_customer,
    total_order_value,
    order_status,
    ROW_NUMBER() OVER (PARTITION BY region_name ORDER BY total_order_value DESC) AS rank
FROM 
    combined_data
WHERE 
    total_order_value IS NOT NULL
ORDER BY 
    region_name, rank;
