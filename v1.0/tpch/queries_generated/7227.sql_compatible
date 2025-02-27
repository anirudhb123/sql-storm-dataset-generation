
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_value
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty * ps.ps_supplycost) > 10000
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        supplier_value DESC
    LIMIT 10
),
OrderDetails AS (
    SELECT 
        li.l_orderkey,
        li.l_partkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales
    FROM 
        lineitem li
    JOIN 
        RankedOrders ro ON li.l_orderkey = ro.o_orderkey
    WHERE 
        ro.order_rank <= 5
    GROUP BY 
        li.l_orderkey, li.l_partkey
)
SELECT 
    tp.s_name AS supplier_name,
    od.l_partkey,
    od.total_sales,
    hp.total_value AS part_total_value
FROM 
    TopSuppliers tp
JOIN 
    OrderDetails od ON tp.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = od.l_partkey
        ORDER BY ps.ps_supplycost ASC 
        FETCH FIRST 1 ROW ONLY
    )
JOIN 
    HighValueParts hp ON od.l_partkey = hp.ps_partkey
WHERE 
    od.total_sales > 1000
ORDER BY 
    tp.supplier_value DESC, 
    od.total_sales DESC;
