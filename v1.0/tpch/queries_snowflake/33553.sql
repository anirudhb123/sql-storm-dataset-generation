
WITH SupplyChain AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost ASC) as supply_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
), 
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MIN(o.o_orderdate) AS first_order_date,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate > DATEADD(year, -1, '1998-10-01')
    GROUP BY 
        o.o_orderkey
), 
Regions AS (
    SELECT 
        r.r_regionkey,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey
)
SELECT 
    sc.s_name,
    p.p_name,
    sc.ps_supplycost,
    sc.ps_availqty,
    os.total_revenue,
    r.nation_count,
    CASE 
        WHEN os.total_revenue IS NULL THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status,
    CASE 
        WHEN sc.ps_availqty < 10 THEN 'Low Stock'
        ELSE 'Sufficient Stock'
    END AS stock_status
FROM 
    SupplyChain sc
LEFT JOIN 
    part p ON sc.p_partkey = p.p_partkey
LEFT JOIN 
    OrderSummary os ON os.o_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o WHERE o.o_custkey IN (SELECT DISTINCT c.c_custkey FROM customer c WHERE c.c_nationkey = sc.s_suppkey))
LEFT JOIN 
    Regions r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = sc.s_suppkey)
WHERE 
    sc.supply_rank = 1
ORDER BY 
    sc.ps_supplycost DESC, 
    r.nation_count ASC;
