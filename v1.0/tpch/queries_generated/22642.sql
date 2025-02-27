WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
),
HighValueOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice
    FROM RankedOrders r
    WHERE r.price_rank <= 5
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_value
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
PopularParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity_sold
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(l.l_quantity) > 100
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT l.l_partkey) AS part_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM HighValueOrders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    sd.s_name AS supplier_name,
    os.part_count,
    os.total_revenue,
    CASE 
        WHEN os.total_revenue > 10000 THEN 'High Revenue'
        WHEN os.total_revenue IS NULL THEN 'No Revenue'
        ELSE 'Moderate Revenue'
    END AS revenue_category,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY os.total_revenue DESC) AS revenue_rank
FROM PopularParts p
JOIN SupplierDetails sd ON sd.total_supply_value > 5000
LEFT JOIN OrderSummary os ON p.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = os.o_orderkey)
WHERE p.total_quantity_sold > 50 AND sd.s_acctbal IS NOT NULL
ORDER BY sd.s_acctbal DESC, p.p_name ASC;
