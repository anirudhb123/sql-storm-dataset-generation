WITH TotalCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
        COUNT(DISTINCT l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
)
SELECT 
    os.o_orderkey,
    os.o_orderdate,
    os.total_amount,
    sc.s_suppkey,
    sc.s_name,
    sc.nation_name,
    tc.total_supply_cost,
    sc.part_count
FROM 
    OrderSummary os
JOIN 
    SupplierDetails sc ON os.item_count = sc.part_count
LEFT JOIN 
    TotalCost tc ON sc.part_count = (SELECT COUNT(*) FROM partsupp WHERE ps_partkey = sc.part_count)
ORDER BY 
    os.total_amount DESC, os.o_orderdate DESC
LIMIT 10;
