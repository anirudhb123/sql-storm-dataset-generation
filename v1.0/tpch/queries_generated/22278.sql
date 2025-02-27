WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = 1))
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Filled'
            WHEN o.o_orderstatus = 'O' THEN 'Open'
            ELSE 'Other'
        END AS order_status,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_price
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderstatus
),
CustomerSegments AS (
    SELECT 
        c.c_custkey,
        c.c_mktsegment,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_mktsegment
)
SELECT 
    r.s_suppkey,
    r.s_name,
    r.s_acctbal,
    fo.o_orderkey,
    fo.total_line_item_price,
    COALESCE(cs.order_count, 0) AS customer_order_count,
    CASE 
        WHEN fo.o_totalprice IS NULL THEN 'No Total Price'
        ELSE 'Total Price Exists'
    END AS price_status
FROM 
    RankedSuppliers r
JOIN 
    FilteredOrders fo ON r.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT DISTINCT ps_partkey FROM partsupp WHERE ps_availqty > 0) LIMIT 1)
LEFT JOIN 
    CustomerSegments cs ON cs.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = fo.o_orderkey LIMIT 1)
WHERE 
    r.rank = 1 
    AND r.s_acctbal IS NOT NULL
ORDER BY 
    r.s_acctbal DESC, 
    fo.total_line_item_price DESC;
