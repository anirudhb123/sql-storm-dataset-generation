WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        p.p_retailprice * ps.ps_availqty AS total_value
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size BETWEEN 10 AND 20
),
SelectedNations AS (
    SELECT
        DISTINCT n.n_nationkey,
        n.n_name
    FROM 
        nation n
    WHERE 
        n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'A%')
),
SupplierAggregates AS (
    SELECT 
        s.s_nationkey,
        AVG(s.s_acctbal) AS avg_acctbal,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    GROUP BY 
        s.s_nationkey
)

SELECT 
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    COALESCE(SUM(sp.total_value), 0) AS total_part_value,
    COUNT(DISTINCT ho.o_orderkey) AS total_orders,
    AVG(sa.avg_acctbal) AS average_supplier_acctbal,
    CASE 
        WHEN COUNT(DISTINCT ho.o_orderkey) > 0 THEN 'High Order Activity'
        ELSE 'Standard Activity'
    END AS activity_status
FROM 
    SelectedNations n
LEFT JOIN 
    SupplierAggregates sa ON n.n_nationkey = sa.s_nationkey
LEFT JOIN 
    SupplierParts sp ON sa.s_nationkey = sp.ps_suppkey
LEFT JOIN 
    HighValueOrders ho ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = ho.o_orderkey)
GROUP BY 
    n.n_name
ORDER BY 
    total_part_value DESC, 
    average_supplier_acctbal DESC
LIMIT 10 OFFSET 5;
