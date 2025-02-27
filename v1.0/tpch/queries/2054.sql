WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ns.n_name AS nation_name,
    ss.s_name AS supplier_name,
    COALESCE(cs.order_count, 0) AS customer_orders,
    ss.total_available, 
    ss.avg_supplycost,
    os.total_sales,
    os.item_count,
    CONCAT('Supplier: ', ss.s_name, ', Nation: ', ns.n_name) AS supplier_nation_info
FROM 
    SupplierStats ss
INNER JOIN 
    nation ns ON ss.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps)
LEFT JOIN 
    OrderStats os ON os.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = ns.n_nationkey LIMIT 1)
LEFT JOIN 
    CustomerOrderCount cs ON ss.s_suppkey = cs.c_custkey 
WHERE 
    (ss.total_available IS NOT NULL)
    AND (ss.avg_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp) OR ss.total_available > 1000)
ORDER BY 
    ss.total_available DESC, 
    os.total_sales DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
