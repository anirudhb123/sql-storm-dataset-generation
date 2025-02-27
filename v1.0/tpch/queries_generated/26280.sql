WITH PartData AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
        STRING_AGG(DISTINCT n.n_name, ', ') AS nations
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type
),
OrderData AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        STRING_AGG(DISTINCT c.c_name, ', ') AS customers,
        STRING_AGG(DISTINCT p.p_name, ', ') AS products
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN part p ON l.l_partkey = p.p_partkey
    GROUP BY 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.p_brand,
    pd.p_type,
    pd.total_available_quantity,
    pd.avg_supply_cost,
    od.o_orderkey,
    od.o_orderdate,
    od.o_totalprice,
    od.customers,
    od.products
FROM PartData pd
LEFT JOIN OrderData od ON pd.p_name = ANY (string_to_array(od.products, ', '))
WHERE pd.total_available_quantity > 100
ORDER BY pd.p_partkey, od.o_orderdate DESC;
