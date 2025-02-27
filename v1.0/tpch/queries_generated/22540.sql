WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate < '2000-01-01')
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 1
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_linenumber,
        CASE 
            WHEN l.l_discount > 0.2 THEN 'High Discount'
            ELSE 'Standard Discount'
        END AS discount_category,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS item_rank
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
)
SELECT 
    r.o_orderkey,
    r.o_orderstatus,
    r.o_totalprice,
    SUM(f.l_extendedprice) AS total_lineitem_price,
    COUNT(DISTINCT f.l_partkey) AS unique_parts,
    s.total_supply_cost,
    CASE 
        WHEN r.o_orderstatus = 'F' THEN 'Finalized'
        ELSE 'Pending'
    END AS order_status_desc
FROM 
    RankedOrders r
LEFT JOIN 
    FilteredLineItems f ON r.o_orderkey = f.l_orderkey
LEFT JOIN 
    SupplierParts s ON f.l_partkey = s.ps_partkey
GROUP BY 
    r.o_orderkey, r.o_orderstatus, r.o_totalprice, s.total_supply_cost
HAVING 
    SUM(f.l_extendedprice) IS NOT NULL 
    AND (r.o_orderstatus IS NULL OR s.total_supply_cost > 10000)
ORDER BY 
    total_lineitem_price DESC, order_status_desc ASC
UNION ALL
SELECT 
    DISTINCT r.o_orderkey,
    r.o_orderstatus,
    NULL AS o_totalprice,
    0 AS total_lineitem_price,
    0 AS unique_parts,
    NULL AS total_supply_cost,
    'No Orders' AS order_status_desc
FROM 
    RankedOrders r
WHERE 
    r.o_orderstatus NOT IN (SELECT DISTINCT o.o_orderstatus FROM orders o);
