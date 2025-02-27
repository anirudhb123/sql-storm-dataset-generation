WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
HighValueOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_linenumber) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierTotals AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        COALESCE(SUM(ps.ps_availqty) FILTER (WHERE ps.ps_supplycost < 50), 0) AS low_cost_supply_qty
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr
    HAVING 
        COUNT(ps.ps_suppkey) > 1
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS high_value_order_count,
    SUM(ht.total_order_value) AS total_high_value_sales,
    STRING_AGG(DISTINCT CONCAT(f.p_name, ' (', f.low_cost_supply_qty, ')') ORDER BY f.low_cost_supply_qty DESC) AS parts_with_low_cost_supply
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    HighValueOrders ht ON o.o_orderkey = ht.o_orderkey
LEFT JOIN 
    FilteredParts f ON f.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT rs.s_suppkey FROM RankedSuppliers rs WHERE rs.rank <= 3))
GROUP BY 
    n.n_name
HAVING 
    COALESCE(SUM(ht.total_order_value), 0) > 50000 OR COUNT(DISTINCT o.o_orderkey) IS NULL
ORDER BY 
    total_high_value_sales DESC NULLS LAST;
