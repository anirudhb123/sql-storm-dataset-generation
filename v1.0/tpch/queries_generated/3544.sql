WITH RegionStats AS (
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
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity,
        COUNT(CASE WHEN l.l_returnflag = 'Y' THEN 1 END) AS return_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)

SELECT 
    rs.r_name,
    cs.c_name,
    cs.order_count,
    cs.total_spent,
    ls.total_revenue,
    ls.avg_quantity,
    rs.nation_count,
    rs.total_supplier_balance
FROM 
    RegionStats rs
INNER JOIN 
    CustomerOrders cs ON rs.nation_count > 2
LEFT JOIN 
    LineItemSummary ls ON cs.order_count > 5
WHERE 
    rs.total_supplier_balance IS NOT NULL
    AND cs.total_spent > 1000.00
ORDER BY 
    rs.r_name, cs.c_name DESC
LIMIT 50;
