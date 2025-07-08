
WITH RECURSIVE RevenueCTE AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '1994-01-01' AND '1994-12-31'
    GROUP BY o.o_orderkey
),
SupplierParts AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 1000
    GROUP BY ps.ps_partkey
),
HighRevenueOrders AS (
    SELECT
        rg.r_name,
        SUM(r.total_revenue) AS regional_revenue
    FROM RevenueCTE r
    JOIN customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = r.o_orderkey)
    JOIN nation n ON n.n_nationkey = c.c_nationkey
    JOIN region rg ON rg.r_regionkey = n.n_regionkey
    GROUP BY rg.r_name
    HAVING SUM(r.total_revenue) > 50000
),
FilteredSupply AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        COALESCE(sp.total_available, 0) AS total_available, 
        COALESCE(sp.avg_cost, 0) AS avg_cost
    FROM part p
    LEFT JOIN SupplierParts sp ON p.p_partkey = sp.ps_partkey
    WHERE p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
)

SELECT 
    hro.r_name, 
    COALESCE(SUM(fs.total_available), 0) AS available_supplies,
    COUNT(DISTINCT fs.p_partkey) AS unique_parts,
    MAX(fs.avg_cost) AS highest_cost,
    (SELECT COUNT(*) FROM lineitem l WHERE l.l_returnflag = 'R') AS return_count
FROM HighRevenueOrders hro
LEFT JOIN FilteredSupply fs ON fs.total_available IS NOT NULL
GROUP BY hro.r_name
ORDER BY available_supplies DESC
OFFSET 1 ROWS FETCH NEXT 5 ROWS ONLY;
