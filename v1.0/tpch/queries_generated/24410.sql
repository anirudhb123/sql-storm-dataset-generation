WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),

OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        l.l_partkey,
        l.l_quantity,
        l.l_discount,
        l.l_tax,
        l.l_returnflag,
        l.l_linestatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1995-01-01' AND 
        l.l_returnflag = 'N' AND 
        l.l_linestatus = 'O'
),

SupplierStats AS (
    SELECT
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost * ps_availqty) FROM partsupp) 
)

SELECT 
    od.o_orderkey,
    od.o_totalprice,
    COUNT(DISTINCT rs.s_suppkey) AS unique_suppliers,
    COALESCE(SUM(oss.total_supply_value), 0) AS total_part_value,
    STRING_AGG(DISTINCT CONCAT('Supplier: ', rs.s_name, ' (Balance: ', rs.s_acctbal, ')'), '; ') AS supplier_details
FROM 
    OrderDetails od
LEFT JOIN 
    SupplierStats oss ON od.l_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_partkey = oss.p_partkey)
LEFT JOIN 
    RankedSuppliers rs ON rs.rn <= 5
GROUP BY 
    od.o_orderkey,
    od.o_totalprice
HAVING 
    SUM(od.l_quantity) > 10 AND 
    MIN(od.l_discount) > 0.05 AND 
    COUNT(od.l_discount) > 0
ORDER BY 
    od.o_totalprice DESC NULLS LAST;
