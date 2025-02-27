WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_acct_balance,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        stats.total_supply_cost
    FROM 
        supplier s
    JOIN 
        SupplierStats stats ON s.s_suppkey = stats.s_suppkey
    WHERE 
        stats.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierStats)
),
OrderSummary AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        COUNT(DISTINCT l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_custkey
)
SELECT 
    cs.c_name,
    cs.c_acctbal,
    COALESCE(hv.total_supply_cost, 0) AS total_supply_cost_from_high_value_suppliers,
    os.total_spent,
    os.order_count,
    os.lineitem_count,
    CASE WHEN os.total_spent IS NULL THEN 'No Orders' 
         ELSE CASE WHEN os.total_spent > 5000 THEN 'High Value' 
                   ELSE 'Regular' 
              END 
    END AS customer_value_category
FROM 
    customer cs
LEFT JOIN 
    HighValueSuppliers hv ON cs.c_nationkey = hv.s_nationkey
LEFT JOIN 
    OrderSummary os ON cs.c_custkey = os.o_custkey
WHERE 
    cs.c_acctbal IS NOT NULL
ORDER BY 
    cs.c_name, os.total_spent DESC;
