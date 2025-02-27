WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS supplier_nation,
        r.r_name AS supplier_region,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts_count
    FROM 
        supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name, r.r_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(l.l_linenumber) AS line_item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipmode IN ('AIR', 'TRUCK')
    GROUP BY 
        l.l_orderkey
)
SELECT 
    sd.s_name,
    sd.supplier_nation,
    sd.supplier_region,
    cs.c_name,
    cs.total_spent,
    cs.total_orders,
    cs.avg_order_value,
    lis.net_revenue,
    lis.line_item_count
FROM 
    SupplierDetails sd
LEFT JOIN 
    CustomerOrderStats cs ON sd.supplied_parts_count > 5
JOIN 
    LineItemSummary lis ON lis.l_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_orderstatus = 'O'
    )
WHERE 
    sd.s_acctbal IS NOT NULL
    AND (sd.supplied_parts_count > 10 OR cs.total_spent > 1000)
ORDER BY 
    cs.total_spent DESC, sd.supplier_region ASC;
