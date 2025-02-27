WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice > 100
),
SupplierOrders AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_discount) AS avg_discount
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' 
      AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY l.l_orderkey, l.l_partkey, l.l_suppkey
),
AggregatedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
FilteredNation AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING COUNT(DISTINCT c.c_custkey) > 0
)
SELECT 
    rp.p_name,
    rp.p_retailprice,
    so.total_quantity,
    so.avg_discount,
    asup.total_available_qty,
    asup.total_supply_cost,
    fn.n_name AS nation_name,
    fn.customer_count
FROM RankedParts rp
LEFT JOIN SupplierOrders so ON rp.p_partkey = so.l_partkey
JOIN AggregatedSuppliers asup ON so.l_suppkey = asup.s_suppkey
JOIN FilteredNation fn ON asup.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rp.p_partkey LIMIT 1)
WHERE rp.price_rank <= 10
  AND fn.customer_count IS NOT NULL
ORDER BY rp.p_retailprice DESC, fn.customer_count DESC;