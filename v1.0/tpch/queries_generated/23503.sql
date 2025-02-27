WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplier_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_suppkey, s.s_name
),
LineitemAnalysis AS (
    SELECT 
        l.l_orderkey,
        COUNT(DISTINCT l.l_suppkey) AS distinct_suppliers,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
        AVG(l.l_extendedprice) AS avg_price
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    coalesce(RO.o_orderkey, LA.l_orderkey) AS order_key,
    RO.o_orderdate,
    COALESCE(RO.o_totalprice, 0) AS total_price,
    COALESCE(LA.distinct_suppliers, 0) AS supplier_count,
    COALESCE(SD.total_supplier_cost, 0) AS supplier_cost,
    CASE 
        WHEN RO.o_orderstatus IS NULL THEN 'UNKNOWN STATUS'
        ELSE RO.o_orderstatus 
    END AS order_status,
    CASE 
        WHEN LA.returned_quantity IS NULL AND RO.o_orderprice > 1000 THEN 'HIGH VALUE'
        ELSE 'NORMAL'
    END AS order_category
FROM RankedOrders RO
FULL OUTER JOIN LineitemAnalysis LA ON RO.o_orderkey = LA.l_orderkey
LEFT JOIN SupplierDetails SD ON SD.ps_partkey IN (SELECT p_partkey FROM part WHERE p_size BETWEEN 1 AND 100)
WHERE 
    (RO.o_orderdate < CURRENT_DATE - INTERVAL '30 DAYS' OR LA.distinct_suppliers IS NOT NULL)
    AND (RO.o_orderstatus IS NOT NULL OR LA.distinct_suppliers > 0)
ORDER BY 
    COALESCE(RO.o_totalprice, 0) DESC,
    order_key DESC
LIMIT 100;
