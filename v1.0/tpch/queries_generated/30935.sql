WITH RECURSIVE RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS total_parts,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        MIN(ps.ps_supplycost) AS min_cost,
        MAX(ps.ps_supplycost) AS max_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueOrders AS (
    SELECT 
        os.o_orderkey,
        os.total_price,
        os.total_parts
    FROM 
        OrderSummary os
    WHERE 
        os.total_price > (SELECT AVG(total_price) FROM OrderSummary)
)
SELECT 
    p.p_name,
    sp.total_available,
    sp.min_cost,
    sp.max_cost,
    (SELECT COUNT(*) FROM HighValueOrders hvo WHERE hvo.o_orderkey = lo.l_orderkey) AS num_high_value_orders,
    COUNT(DISTINCT s.s_suppkey) AS num_suppliers,
    AVG(s.s_acctbal) AS avg_supplier_balance
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem lo ON ps.ps_partkey = lo.l_partkey
WHERE 
    p.p_retailprice > 100 AND
    (s.rank <= 5 OR s.s_name IS NULL)
GROUP BY 
    p.p_name, sp.total_available, sp.min_cost, sp.max_cost
HAVING 
    COUNT(DISTINCT lo.l_orderkey) > 0
ORDER BY 
    p.p_name;
