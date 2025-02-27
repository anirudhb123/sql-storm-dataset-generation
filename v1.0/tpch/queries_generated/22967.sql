WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, CURRENT_DATE)
),
SupplierAggregates AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
WrappedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_discount,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS item_position
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
),
SupplierWithRegion AS (
    SELECT 
        s.s_suppkey,
        r.r_name,
        s.s_acctbal,
        s.s_name
    FROM 
        supplier s
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name IS NOT NULL
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment, 
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'N/A' 
            WHEN c.c_acctbal < 0 THEN 'Negative Balance' 
            ELSE 'Positive Balance' 
        END AS balance_status
    FROM 
        customer c
    WHERE 
        c.c_mktsegment IN ('AUTO', 'FURN', 'TECH')
)
SELECT 
    fo.o_orderkey,
    COUNT(DISTINCT s.s_suppkey) AS related_suppliers,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
    AVG(sa.avg_supply_cost) AS average_supplier_cost,
    MAX(fo.o_totalprice) AS max_order_price,
    STRING_AGG(DISTINCT c.c_name, '; ') AS customer_names
FROM 
    RankedOrders fo
JOIN 
    WrappedLineItems li ON fo.o_orderkey = li.l_orderkey
LEFT JOIN 
    SupplierAggregates sa ON li.l_partkey = sa.ps_partkey
RIGHT JOIN 
    SupplierWithRegion s ON sa.ps_partkey = s.s_suppkey
JOIN 
    FilteredCustomers c ON fo.o_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o WHERE o.o_custkey = c.c_custkey)
WHERE 
    fo.rank = 1 AND 
    fo.o_orderstatus IN ('O', 'F') AND 
    (s.s_acctbal IS NULL OR s.s_acctbal >= 100.00)
GROUP BY 
    fo.o_orderkey
ORDER BY 
    total_sales DESC
LIMIT 100;
