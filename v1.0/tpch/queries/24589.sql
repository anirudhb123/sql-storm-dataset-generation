
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
        AND o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),
SupplierAggregates AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        MAX(s.s_acctbal) AS max_acct_bal,
        MIN(s.s_acctbal) AS min_acct_bal
    FROM 
        partsupp ps 
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_suppkey
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sa.total_avail_qty,
        sa.part_count
    FROM 
        supplier s 
    JOIN 
        SupplierAggregates sa ON s.s_suppkey = sa.ps_suppkey
    WHERE 
        sa.total_avail_qty > 1000 AND sa.part_count > 5
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    AVG(order_summaries.total_order_value) AS avg_order_value,
    COUNT(DISTINCT f.s_suppkey) AS active_supplier_count,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    FilteredSuppliers f ON n.n_nationkey = f.s_suppkey
JOIN 
    (SELECT 
         o.o_orderkey,
         SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
     FROM 
         orders o 
     JOIN 
         lineitem l ON o.o_orderkey = l.l_orderkey
     GROUP BY 
         o.o_orderkey) order_summaries ON order_summaries.o_orderkey IN (SELECT o_orderkey FROM RankedOrders WHERE rn <= 10)
LEFT JOIN 
    part p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = f.s_suppkey)
WHERE 
    r.r_name IS NOT NULL 
    AND n.n_nationkey IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT n.n_nationkey) > 1
ORDER BY 
    avg_order_value DESC 
LIMIT 20;
