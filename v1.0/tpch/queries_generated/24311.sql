WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(month, -6, GETDATE())
), 
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CAST(SUM(ps.ps_supplycost * ps.ps_availqty) AS DECIMAL(12, 2)) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
), 
NullValueLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        ISNULL(l.l_returnflag, 'N') AS l_returnflag, 
        ISNULL(l.l_linestatus, 'O') AS l_linestatus
    FROM 
        lineitem l
    WHERE 
        l.l_discount IS NULL
    OR 
        l.l_tax IS NULL
), 
TopNations AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        RANK() OVER (ORDER BY COUNT(DISTINCT o.o_orderkey) DESC) AS nation_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        lineitem l ON s.s_suppkey = l.l_suppkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_extended_price,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
    AVG(l.l_tax) OVER (PARTITION BY p.p_partkey) AS avg_tax,
    (SELECT COUNT(*) FROM RankedOrders ro WHERE ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')) AS active_orders_count,
    (SELECT COUNT(DISTINCT n.n_nationkey) FROM TopNations tn WHERE tn.nation_rank <= 5) AS top_nations_count
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    HighValueSuppliers hvs ON l.l_suppkey = hvs.s_suppkey
WHERE 
    COALESCE(hvs.total_supply_value, 0) > 70000
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    total_extended_price > (
        SELECT AVG(l_extendedprice) FROM lineitem
    )
ORDER BY 
    total_extended_price DESC;
