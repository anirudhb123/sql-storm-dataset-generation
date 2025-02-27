WITH RankedSales AS (
    SELECT 
        l_orderkey,
        l_partkey,
        l_suppkey,
        l_linenumber,
        SUM(l_extendedprice * (1 - l_discount)) AS net_sales,
        ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS rn
    FROM 
        lineitem
    GROUP BY 
        l_orderkey, l_partkey, l_suppkey, l_linenumber
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        AVG(ps.ps_supplycost * ps.ps_availqty) AS avg_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT 
        DISTINCT o.o_orderkey, 
        o.o_totalprice,
        CUME_DIST() OVER (ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS line_count,
        MAX(l.l_shipdate) AS last_ship_date,
        MIN(l.l_commitdate) AS first_commit_date
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    n.n_name,
    SUM(COALESCE(S.avg_supply_value, 0)) AS total_avg_supply_value,
    COUNT(DISTINCT H.o_orderkey) AS high_value_order_count,
    AVG(D.total_revenue) AS avg_order_revenue,
    MIN(D.first_commit_date) AS earliest_commit_date,
    MAX(D.last_ship_date) AS latest_ship_date
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats S ON s.s_suppkey = S.s_suppkey
LEFT JOIN 
    HighValueOrders H ON H.o_orderkey IN (SELECT l_orderkey FROM lineitem WHERE l_suppkey = s.s_suppkey)
LEFT JOIN 
    OrderDetails D ON D.o_orderkey = H.o_orderkey
GROUP BY 
    n.n_name
HAVING 
    SUM(S.total_avg_supply_value) IS NOT NULL AND 
    COUNT(DISTINCT H.o_orderkey) > 0
ORDER BY 
    n.n_name;
