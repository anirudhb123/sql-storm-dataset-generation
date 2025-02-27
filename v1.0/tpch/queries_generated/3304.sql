WITH SupplierCosts AS (
    SELECT 
        ps.p_partkey,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.p_partkey, s.s_nationkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COALESCE(SUM(oc.total_supplycost), 0) AS total_supply_cost,
    AVG(od.total_price) AS avg_order_value,
    MAX(sc.total_supplycost) AS max_supply_cost
FROM 
    nation n
LEFT JOIN 
    SupplierCosts sc ON n.n_nationkey = sc.s_nationkey
LEFT JOIN 
    OrderDetails od ON sc.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey IN (
            SELECT s.s_suppkey
            FROM supplier s 
            WHERE s.s_nationkey = n.n_nationkey
        )
    )
LEFT JOIN 
    (
        SELECT 
            p.p_partkey,
            SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
        FROM 
            partsupp ps
        JOIN 
            part p ON ps.ps_partkey = p.p_partkey
        GROUP BY 
            p.p_partkey
    ) oc ON od.part_count > 0
GROUP BY 
    n.n_name
ORDER BY 
    total_orders DESC, nation_name ASC;
