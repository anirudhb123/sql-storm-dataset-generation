WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2000-01-01' AND o.o_orderdate < '2001-01-01'
),
TotalLineItemCosts AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_cost
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerBalances AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 0
            ELSE c.c_acctbal 
        END AS adjusted_balance
    FROM 
        customer c
)
SELECT 
    o.o_orderkey,
    o.o_orderstatus,
    COALESCE(ROUND(t.total_cost, 2), 0) AS total_line_item_cost,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    rb.adjusted_balance,
    CASE 
        WHEN rb.rnk = 1 THEN 'Most Recent Status'
        ELSE 'Older Status'
    END AS order_recency,
    s.part_count
FROM 
    RankedOrders rb
JOIN 
    TotalLineItemCosts t ON rb.o_orderkey = t.l_orderkey
LEFT JOIN 
    supplier s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = rb.o_orderkey) LIMIT 1)
JOIN 
    CustomerBalances c ON rb.o_custkey = c.c_custkey
WHERE 
    (s.total_supply_cost IS NULL OR s.total_supply_cost > 100.00)
    AND (rb.o_orderstatus IN ('O', 'F') OR rb.o_orderstatus IS NULL)
ORDER BY 
    rb.o_orderdate DESC,
    c.adjusted_balance DESC;
