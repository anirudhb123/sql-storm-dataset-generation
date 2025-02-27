WITH RECURSIVE PriceRankings AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
),
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(ps.ps_partkey) AS supply_count, 
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate > '2022-01-01'
    GROUP BY 
        o.o_orderkey
)

SELECT 
    r.r_name AS region_name, 
    n.n_name AS nation_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(ss.total_supply_cost) AS total_supplier_cost,
    SUM(CASE WHEN pr.rank <= 10 THEN pr.p_retailprice ELSE 0 END) AS top_10_parts_cost,
    AVG(od.total_order_value) AS average_order_value
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    PriceRankings pr ON s.s_suppkey = pr.p_partkey
LEFT JOIN 
    OrderDetails od ON od.o_orderkey = (
        SELECT 
            o2.o_orderkey 
        FROM 
            orders o2 
        WHERE 
            o2.o_custkey = s.s_suppkey
        ORDER BY 
            o2.o_orderdate DESC 
        LIMIT 1
    )
GROUP BY 
    region_name, nation_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 0 
    AND SUM(ss.total_supply_cost) IS NOT NULL
ORDER BY 
    average_order_value DESC;
