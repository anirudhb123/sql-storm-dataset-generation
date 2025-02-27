WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.c_mktsegment,
    COALESCE(sc.total_supply_cost, 0) AS total_supply_cost,
    ts.supplier_nation
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierCost sc ON r.o_orderkey = sc.ps_partkey
LEFT JOIN 
    TopSuppliers ts ON ts.s_supplier_nation = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT DISTINCT s.s_nationkey FROM supplier s WHERE s.s_suppkey = sc.ps_partkey) LIMIT 1)
WHERE 
    r.rank <= 5
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;
