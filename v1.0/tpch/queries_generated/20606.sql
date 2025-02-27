WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        MAX(s.s_acctbal) AS max_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
ProductAnalysis AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        AVG(l.l_extendedprice) AS avg_price,
        CASE WHEN SUM(l.l_quantity) IS NULL THEN 'Out of stock' ELSE 'In stock' END AS stock_status
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    p.p_name,
    s.total_supply_cost,
    ps.avg_price,
    ps.stock_status
FROM 
    RankedOrders r
LEFT JOIN 
    ProductAnalysis ps ON r.o_orderkey = (SELECT MAX(o.o_orderkey) FROM orders o WHERE o.o_orderdate <= r.o_orderdate)
LEFT JOIN 
    SupplierStats s ON s.total_parts > 10
WHERE 
    r.rn < 10 
    AND r.o_totalprice BETWEEN (SELECT AVG(o2.o_totalprice) FROM RankedOrders o2) * 0.9 AND (SELECT AVG(o2.o_totalprice) FROM RankedOrders o2) * 1.1
ORDER BY 
    r.o_orderdate DESC, ps.avg_price ASC;
