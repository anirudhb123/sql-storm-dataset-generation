WITH RegionStats AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
PartSupplierSummary AS (
    SELECT 
        ps.ps_partkey,
        COUNT(*) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OrderDetails AS (
    SELECT 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        AVG(l.l_quantity) AS avg_quantity_per_line,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('F', 'O')
    GROUP BY 
        o.o_custkey
)
SELECT
    r.r_name,
    p.p_name,
    ps.supplier_count, 
    ps.total_supply_cost,
    od.total_order_value,
    od.avg_quantity_per_line
FROM 
    RegionStats r
FULL OUTER JOIN 
    PartSupplierSummary ps ON r.nation_count = ps.supplier_count
JOIN 
    part p ON p.p_partkey = ps.ps_partkey
JOIN 
    OrderDetails od ON od.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal > od.total_order_value)
WHERE 
    (r.total_account_balance IS NOT NULL OR ps.total_supply_cost IS NULL)
    AND (od.line_item_count > 0 OR od.avg_quantity_per_line IS NULL)
ORDER BY 
    r.r_name ASC, p.p_name DESC;
