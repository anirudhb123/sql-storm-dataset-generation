WITH RECURSIVE RegionStats AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        count(DISTINCT n.n_nationkey) AS nation_count,
        SUM(COALESCE(s.s_acctbal, 0)) AS total_supplier_acctbal
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '2022-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    rs.r_name,
    COALESCE(ROUND(AVG(os.total_revenue), 2), 0) AS avg_order_revenue,
    MAX(os.order_rank) AS max_order_rank,
    STRING_AGG(DISTINCT s.s_name, ', ') FILTER (WHERE s.s_nationkey IS NULL) AS orphaned_suppliers,
    COUNT(DISTINCT CASE WHEN os.o_orderstatus = 'F' THEN os.o_orderkey END) AS finished_orders,
    SUM(CASE 
            WHEN s.s_acctbal IS NOT NULL THEN s.s_acctbal
            ELSE 0 
        END) AS non_null_acctbal
FROM 
    RegionStats rs
LEFT JOIN 
    supplier s ON rs.r_regionkey = s.s_nationkey
LEFT JOIN 
    OrderStats os ON os.o_orderkey = (SELECT o.o_orderkey 
                                       FROM orders o 
                                       WHERE o.o_custkey = s.s_suppkey AND o.o_orderstatus = 'O' 
                                       ORDER BY o.o_orderdate DESC 
                                       LIMIT 1)
GROUP BY 
    rs.r_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5 OR SUM(rs.total_supplier_acctbal) IS NULL
ORDER BY 
    avg_order_revenue DESC NULLS LAST;
