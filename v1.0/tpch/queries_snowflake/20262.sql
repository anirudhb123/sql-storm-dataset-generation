
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rank_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_partkey
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            WHEN o.o_orderstatus = 'P' THEN 'Pending'
            ELSE 'Other' 
        END AS order_status_description
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate >= DATE '1997-01-01')
),
AggregatedLineItems AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(COALESCE(ali.total_sales, 0)) AS total_sales,
    AVG(ali.item_count) AS avg_items_per_order,
    MAX(rs.total_supply_cost) AS max_supply_cost,
    MIN(rs.total_supply_cost) AS min_supply_cost
FROM 
    nation n
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    orders o ON o.o_custkey = c.c_custkey
LEFT JOIN 
    FilteredOrders fo ON fo.o_orderkey = o.o_orderkey
LEFT JOIN 
    AggregatedLineItems ali ON ali.l_orderkey = fo.o_orderkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_size BETWEEN 20 AND 50
        ) 
        ORDER BY ps.ps_availqty DESC 
        LIMIT 1
    )
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0 AND
    MAX(rs.total_supply_cost) IS NOT NULL
ORDER BY 
    n.n_name ASC
LIMIT 10 OFFSET 5;
