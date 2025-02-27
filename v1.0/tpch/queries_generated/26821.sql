WITH NationSupplier AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
PartInfo AS (
    SELECT 
        p.p_name AS part_name,
        p.p_retailprice,
        COUNT(ps.ps_suppkey) AS available_suppliers
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_name, p.p_retailprice
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        c.c_name AS customer_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name
)
SELECT 
    ns.nation_name,
    ns.supplier_count,
    ns.supplier_names,
    pi.part_name,
    pi.p_retailprice,
    pi.available_suppliers,
    od.customer_name,
    od.total_value
FROM 
    NationSupplier ns
JOIN 
    PartInfo pi ON ns.nation_name LIKE '%United%'
JOIN 
    OrderDetails od ON pi.available_suppliers > 5
ORDER BY 
    ns.supplier_count DESC, pi.p_retailprice ASC;
