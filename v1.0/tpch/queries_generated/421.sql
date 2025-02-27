WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        SUM(CASE WHEN li.l_discount > 0 THEN li.l_extendedprice * (1 - li.l_discount) ELSE 0 END) AS discounted_price,
        SUM(li.l_extendedprice) AS total_price,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY li.l_linenumber) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
),
HighValueOrders AS (
    SELECT 
        o.*,
        od.discounted_price,
        od.total_price
    FROM 
        orders o
    JOIN 
        OrderDetails od ON o.o_orderkey = od.o_orderkey
    WHERE 
        od.discounted_price > 500.00
),
FinalOutput AS (
    SELECT 
        r.r_name,
        n.n_name,
        s.s_name,
        ss.total_supplycost,
        h.total_price,
        h.o_orderdate,
        h.o_orderkey
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierStats ss ON s.s_suppkey = ss.s_suppkey
    INNER JOIN 
        HighValueOrders h ON s.s_suppkey IN (
            SELECT ps.ps_suppkey 
            FROM partsupp ps 
            WHERE ps.ps_partkey IN (
                SELECT l.l_partkey 
                FROM lineitem l 
                WHERE l.l_orderkey = h.o_orderkey
            )
        )
)
SELECT 
    r_name,
    n_name,
    s_name,
    SUM(total_supplycost) AS total_supplycost_across_orders,
    COUNT(DISTINCT o_orderkey) AS order_count,
    AVG(total_price) AS avg_order_price
FROM 
    FinalOutput
GROUP BY 
    r_name, n_name, s_name
HAVING 
    SUM(total_supplycost) IS NOT NULL
ORDER BY 
    total_supplycost_across_orders DESC;
