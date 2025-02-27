WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
HighValueSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.nation_name,
        sd.total_available_qty,
        sd.total_supply_cost,
        RANK() OVER (ORDER BY sd.total_supply_cost DESC) AS supplier_rank
    FROM SupplierDetails sd
    WHERE sd.total_available_qty > 1000
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_shippriority,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderdate >= DATEADD(month, -6, GETDATE())
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_shippriority
)
SELECT 
    hs.s_name, 
    hs.nation_name, 
    rs.o_orderkey, 
    rs.total_order_value,
    CASE 
        WHEN rs.o_shippriority = 1 THEN 'High'
        WHEN rs.o_shippriority = 2 THEN 'Medium'
        ELSE 'Low'
    END AS ShippingPriority,
    (SELECT COUNT(*)
     FROM lineitem li
     WHERE li.l_orderkey = rs.o_orderkey
       AND li.l_returnflag = 'R') AS total_returns
FROM HighValueSuppliers hs
JOIN RecentOrders rs ON hs.s_suppkey IN (
    SELECT DISTINCT ps_suppkey 
    FROM partsupp 
    WHERE ps_partkey IN (
        SELECT l_partkey 
        FROM lineitem 
        WHERE l_orderkey = rs.o_orderkey
    )
)
WHERE hs.s_acctbal IS NOT NULL
ORDER BY hs.total_supply_cost DESC, rs.total_order_value ASC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
