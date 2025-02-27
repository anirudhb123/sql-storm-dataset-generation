WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)  -- Only orders above average price
)
SELECT 
    hp.p_name,
    hp.p_brand,
    SUM(l.l_quantity) AS total_quantity_sold,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    AVG(s.s_acctbal) AS average_supplier_balance,
    hi.c_name AS customer_name,
    hi.o_orderdate
FROM 
    RankedParts hp
JOIN 
    partsupp ps ON hp.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_suppkey = l.l_suppkey AND ps.ps_partkey = l.l_partkey
JOIN 
    HighValueOrders hi ON l.l_orderkey = hi.o_orderkey
JOIN 
    SupplierInfo s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    hp.rn = 1  -- Only the highest priced part per brand
GROUP BY 
    hp.p_name, hp.p_brand, hi.c_name, hi.o_orderdate
ORDER BY 
    total_quantity_sold DESC, average_supplier_balance DESC
LIMIT 100;  -- Limit results for performance benchmarking
