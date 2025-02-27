WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(YEAR, -1, GETDATE())
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 1000000
),
OrderLineItems AS (
    SELECT 
        li.l_orderkey, 
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_price
    FROM 
        lineitem li
    WHERE 
        li.l_returnflag = 'N'
    GROUP BY 
        li.l_orderkey
)
SELECT 
    r.r_name,
    COALESCE(SUM(CASE WHEN ro.o_orderstatus = 'O' THEN roi.total_price END), 0) AS open_order_value,
    COALESCE(SUM(CASE WHEN ro.o_orderstatus = 'F' THEN roi.total_price END), 0) AS finished_order_value,
    COUNT(DISTINCT os.s_suppkey) AS supplier_count,
    (SELECT COUNT(DISTINCT c.c_custkey) 
     FROM customer c 
     WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)) AS customer_count,
    COUNT(DISTINCT li.l_orderkey) AS lineitem_count
FROM 
    region r
LEFT JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN 
    OrderLineItems roi ON roi.l_orderkey = ro.o_orderkey
LEFT JOIN 
    HighValueSuppliers os ON os.total_supply_value > all (SELECT total_supply_value FROM HighValueSuppliers WHERE s_suppkey = os.s_suppkey)
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    r.r_name ASC;
