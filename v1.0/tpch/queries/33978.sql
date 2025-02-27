WITH RECURSIVE OrderTotals AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
RankedOrders AS (
    SELECT 
        ot.o_orderkey,
        ot.o_orderdate,
        ot.total_revenue,
        RANK() OVER (ORDER BY ot.total_revenue DESC) AS rank
    FROM OrderTotals ot
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighVolumeSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.total_supplycost
    FROM SupplierDetails sd
    WHERE sd.total_supplycost > (SELECT AVG(total_supplycost) FROM SupplierDetails)
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    COALESCE(hs.s_name, 'No Supplier') AS supplier_name,
    o.total_revenue,
    CASE 
        WHEN o.total_revenue IS NULL THEN 'Revenue Not Calculated'
        WHEN o.total_revenue > 10000 THEN 'High Revenue'
        ELSE 'Standard Revenue'
    END AS revenue_category
FROM RankedOrders o
LEFT JOIN HighVolumeSuppliers hs ON o.o_orderkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = hs.s_suppkey LIMIT 1)
WHERE o.rank <= 10
ORDER BY o.o_orderdate DESC;
