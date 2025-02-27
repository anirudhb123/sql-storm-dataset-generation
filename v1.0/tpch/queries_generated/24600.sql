WITH RegionalCustomerStats AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        SUM(c.c_acctbal) AS total_acctbal,
        AVG(c.c_acctbal) AS avg_acctbal,
        CASE WHEN COUNT(DISTINCT c.c_custkey) = 0 THEN NULL ELSE SUM(c.c_acctbal)/COUNT(DISTINCT c.c_custkey) END AS avg_balance_per_customer
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_name, r.r_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers,
        AVG(l.l_quantity) AS avg_quantity_per_item,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        MAX(CASE WHEN ps.ps_availqty < 10 THEN 'LOW STOCK' ELSE 'NORMAL' END) AS stock_status
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)

SELECT 
    rcs.nation_name,
    rcs.region_name,
    rcs.total_customers,
    rcs.total_acctbal,
    rcs.avg_acctbal,
    os.total_revenue,
    os.unique_suppliers,
    os.avg_quantity_per_item,
    ss.parts_supplied,
    ss.total_supply_cost,
    CASE 
        WHEN rcs.total_acctbal IS NULL OR rcs.total_acctbal < 1000 THEN 'Economically Low'
        WHEN rcs.total_acctbal BETWEEN 1000 AND 5000 THEN 'Middle-Class'
        ELSE 'Wealthy'
    END AS economic_status,
    COALESCE(ss.stock_status, 'UNDEFINED') AS supplier_stock_status
FROM RegionalCustomerStats rcs
FULL OUTER JOIN OrderStats os ON rcs.nation_name IS NOT NULL AND os.revenue_rank = 1
LEFT JOIN SupplierStats ss ON os.unique_suppliers IS NOT NULL AND ss.parts_supplied > 0
WHERE rcs.total_customers > 5 
    AND (os.total_revenue > 10000 OR ss.total_supply_cost IS NOT NULL)
ORDER BY rcs.region_name, rcs.nation_name;
