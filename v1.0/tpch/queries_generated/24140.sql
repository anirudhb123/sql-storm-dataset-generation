WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('F', 'O')
    GROUP BY 
        o.o_orderkey
),
SupplierPartQuantity AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    ns.n_name,
    p.p_name,
    COALESCE(r.total_revenue, 0) AS revenue,
    COALESCE(total_available, 0) AS available_qty,
    CASE 
        WHEN p.p_retailprice IS NULL THEN 'No Price'
        WHEN p.p_retailprice > 100.00 THEN 'Expensive'
        ELSE 'Affordable'
    END AS price_category
FROM 
    nation ns
LEFT JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.rank = 1
LEFT JOIN 
    HighValueParts p ON rs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey LIMIT 1)
LEFT JOIN 
    OrderSummary r ON r.o_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = ns.n_nationkey))
LEFT JOIN 
    SupplierPartQuantity spq ON p.p_partkey = spq.ps_partkey AND spq.ps_suppkey = s.s_suppkey
WHERE 
    ns.r_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'A%')
ORDER BY 
    revenue DESC NULLS LAST
LIMIT 50 OFFSET 10;
