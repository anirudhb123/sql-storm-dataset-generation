WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2022-01-01' AND 
        o.o_orderdate < '2023-01-01'
    GROUP BY 
        o.o_orderkey
),
RegionSales AS (
    SELECT 
        r.r_regionkey,
        SUM(os.total_revenue) AS region_revenue,
        COUNT(DISTINCT os.o_orderkey) AS orders_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        OrderSummary os ON os.o_orderkey IN (
            SELECT o.o_orderkey 
            FROM orders o 
            JOIN customer c ON o.o_custkey = c.c_custkey
            WHERE c.c_nationkey = n.n_nationkey
        )
    GROUP BY 
        r.r_regionkey
)
SELECT 
    r.r_name,
    COALESCE(rs.region_revenue, 0) AS total_revenue,
    (SELECT COUNT(DISTINCT l.l_partkey) 
     FROM lineitem l 
     JOIN orders o ON o.o_orderkey = l.l_orderkey 
     WHERE l.l_shipdate > '2022-07-01') AS total_distinct_parts,
    (SELECT AVG(total_revenue) 
     FROM OrderSummary) AS avg_order_revenue
FROM 
    region r
LEFT JOIN 
    RegionSales rs ON r.r_regionkey = rs.r_regionkey
WHERE 
    EXISTS (SELECT 1 
            FROM RankedSuppliers rsup 
            WHERE rsup.rnk = 1 AND 
                  rsup.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier))
ORDER BY 
    r.r_name;
