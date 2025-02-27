WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS total_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
NationSupplier AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(os.total_revenue, 0) AS total_revenue,
    ns.supplier_count,
    (COALESCE(ss.total_supply_cost, 0) + COALESCE(os.total_revenue, 0)) AS combined_value
FROM 
    NationSupplier ns
LEFT JOIN 
    SupplierSummary ss ON ns.n_nationkey = ss.s_suppkey
LEFT JOIN 
    OrderSummary os ON ns.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = os.o_orderkey)
ORDER BY 
    combined_value DESC
LIMIT 10;