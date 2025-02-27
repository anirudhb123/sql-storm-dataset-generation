WITH RankedOrders AS (
    SELECT 
        o_orderkey, 
        o_custkey, 
        o_orderstatus, 
        o_totalprice, 
        o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o_orderstatus ORDER BY o_totalprice DESC) AS rnk
    FROM 
        orders
    WHERE 
        o_orderstatus IN ('O', 'F') 
        AND o_totalprice > (
            SELECT AVG(o_totalprice) 
            FROM orders 
            WHERE o_orderdate < '2022-01-01'
        )
), HighValueSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        SUM(ps_supplycost * ps_availqty) AS total_supply_value
    FROM 
        supplier 
    JOIN 
        partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
    GROUP BY 
        s_suppkey, s_name
    HAVING 
        SUM(ps_supplycost * ps_availqty) > (
            SELECT AVG(ps_supplycost * ps_availqty) 
            FROM partsupp
            GROUP BY ps_partkey
        )
), RecentShipments AS (
    SELECT 
        l_orderkey, 
        SUM(l_quantity) AS total_quantity, 
        MAX(l_shipdate) AS last_shipdate
    FROM 
        lineitem
    GROUP BY 
        l_orderkey
    HAVING 
        COUNT(DISTINCT l_shipinstruct) > 2
)

SELECT 
    r.o_orderkey,
    CASE WHEN hs.total_supply_value IS NULL THEN 'No Supplier' ELSE hs.s_name END AS supplier_name,
    rs.total_quantity,
    (SELECT COUNT(*) FROM customer WHERE c_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')) AS usa_customers,
    (SELECT MIN(o_totalprice) FROM RankedOrders WHERE o_custkey = r.o_custkey) AS min_order_value
FROM 
    RankedOrders r
LEFT JOIN 
    HighValueSuppliers hs ON hs.s_suppkey = (
        SELECT ps_suppkey 
        FROM partsupp 
        WHERE ps_partkey IN (
            SELECT l_partkey FROM lineitem WHERE l_orderkey = r.o_orderkey
        ) LIMIT 1
    )
JOIN 
    RecentShipments rs ON r.o_orderkey = rs.l_orderkey
WHERE 
    rnk <= 10 
    AND r.o_orderdate BETWEEN '2023-01-01' AND CURRENT_DATE
ORDER BY 
    r.o_orderkey ASC, 
    supplier_name DESC;
