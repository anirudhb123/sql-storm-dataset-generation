WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_nationkey
),
ProductDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
)
SELECT 
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(p.p_retailprice) AS avg_part_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS product_names,
    AVG(pdi.avg_supply_cost) AS avg_cost_per_supplier
FROM RankedOrders o
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN Customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN ProductDetails p ON l.l_partkey = p.p_partkey
LEFT JOIN SupplierPartInfo pdi ON p.p_partkey = pdi.ps_partkey AND n.n_nationkey = pdi.s_nationkey
WHERE o.o_orderstatus IN ('O', 'F')
  AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
  AND r.r_name IS NOT NULL
  AND (SUM(l.l_quantity) > 0 OR o.o_totalprice < 10000.00)
GROUP BY r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
   AND AVG(p.p_retailprice) IS NOT NULL
   AND STRING_AGG(DISTINCT p.p_name, ', ') IS NOT NULL;
