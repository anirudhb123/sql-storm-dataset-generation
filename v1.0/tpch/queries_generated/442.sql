WITH RankedSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_sales
    FROM
        lineitem l
    GROUP BY
        l.l_orderkey
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(DISTINCT l.l_linenumber) AS total_items,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_item_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    o.o_orderkey,
    os.total_items,
    os.avg_item_price,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
    rs.total_sales
FROM 
    OrderSummary os
JOIN 
    orders o ON os.o_orderkey = o.o_orderkey
LEFT JOIN 
    SupplierDetails s ON s.s_suppkey = (SELECT ps.ps_suppkey 
                                         FROM partsupp ps 
                                         WHERE ps.ps_partkey IN (SELECT l.l_partkey 
                                                                 FROM lineitem l 
                                                                 WHERE l.l_orderkey = o.o_orderkey)
                                         ORDER BY ps.ps_supplycost DESC LIMIT 1)
LEFT JOIN 
    RankedSales rs ON rs.l_orderkey = o.o_orderkey
WHERE 
    os.total_items > 5
ORDER BY 
    total_supply_cost DESC, total_sales DESC;
