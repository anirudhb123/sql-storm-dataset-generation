WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2021-01-01' AND o.o_orderstatus IN ('F', 'O', 'P')
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(SUM(sc.total_supply_cost), 0) AS total_cost
    FROM 
        supplier s
    LEFT JOIN 
        SupplierCosts sc ON s.s_suppkey = sc.ps_suppkey
    WHERE 
        s.s_acctbal > 10000
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
    HAVING 
        COALESCE(SUM(sc.total_supply_cost), 0) < (SELECT AVG(total_supply_cost) FROM SupplierCosts)
)
SELECT 
    DISTINCT p.p_name,
    p.p_brand,
    p.p_type,
    COALESCE(r.r_name, 'Unknown') AS region,
    h.total_cost,
    o.o_totalprice,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Completed'
        WHEN o.o_orderstatus = 'O' THEN 'Open'
        ELSE 'Pending'
    END AS order_status,
    COUNT(DISTINCT l.l_orderkey) OVER (PARTITION BY p.p_partkey) AS order_count,
    STRING_AGG(DISTINCT h.s_name, ', ') FILTER (WHERE h.total_cost > 5000) AS supplier_names
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey) 
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    HighValueSuppliers h ON h.s_suppkey = l.l_suppkey
WHERE 
    p.p_size BETWEEN 1 AND 5 
    AND h.total_cost IS NOT NULL 
    AND l.l_discount IS NOT NULL 
    AND (o.o_orderstatus IS NULL OR o.o_orderstatus IN ('F', 'O'))
ORDER BY 
    order_count DESC, 
    p.p_retailprice DESC;
