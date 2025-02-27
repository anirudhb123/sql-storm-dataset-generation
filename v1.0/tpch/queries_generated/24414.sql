WITH RegionalSummary AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance,
        AVG(s.s_acctbal) AS avg_supplier_balance
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
),
OrderDetails AS (
    SELECT
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        DENSE_RANK() OVER (PARTITION BY c.c_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS value_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name
),
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FilteredOrders AS (
    SELECT 
        od.o_orderkey,
        od.c_name,
        od.total_order_value
    FROM 
        OrderDetails od
    WHERE 
        od.value_rank <= 5
)
SELECT 
    rs.r_name,
    COUNT(DISTINCT fo.o_orderkey) AS top_orders_count,
    SUM(sp.total_supply_cost) AS total_supply_costs,
    AVG(sp.total_available_qty) AS avg_qty_available
FROM 
    RegionalSummary rs
LEFT JOIN 
    SupplierPartInfo sp ON sp.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps)
LEFT JOIN 
    FilteredOrders fo ON fo.total_order_value > 10000
GROUP BY 
    rs.r_name
HAVING 
    SUM(sp.total_supply_cost) IS NOT NULL 
    AND COUNT(DISTINCT fo.o_orderkey) > 0
ORDER BY 
    total_supply_costs DESC NULLS LAST;
