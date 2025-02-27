WITH RECURSIVE RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
AvailableParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    CASE 
        WHEN SUM(l.l_discount) IS NULL THEN 'No Discount Applied'
        ELSE CONCAT('Total Discount: ', SUM(l.l_discount))
    END AS discount_details,
    rs.nation_name,
    RANK() OVER (PARTITION BY rs.s_suppkey ORDER BY COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) DESC) AS order_rank
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey
WHERE 
    p.p_size BETWEEN 10 AND 20
GROUP BY 
    p.p_partkey, p.p_name, rs.s_suppkey, rs.nation_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 0
ORDER BY 
    total_quantity DESC
LIMIT 50
UNION ALL
SELECT 
    hp.ps_partkey,
    'High Value Order' AS p_name,
    0 AS total_quantity,
    'N/A' AS discount_details,
    nd.n_name AS nation_name,
    1 AS order_rank
FROM 
    AvailableParts hp
JOIN 
    HighValueOrders hv ON hp.ps_partkey = hv.o_custkey
JOIN 
    SupplierDetails nd ON hv.o_orderkey = nd.s_suppkey
WHERE 
    hp.total_availqty > 100
ORDER BY 
    total_quantity DESC;
