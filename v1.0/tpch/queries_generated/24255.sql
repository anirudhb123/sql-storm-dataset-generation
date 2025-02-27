WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(CASE WHEN ps.ps_availqty IS NULL THEN 0 ELSE ps.ps_availqty END) AS total_availqty,
        MIN(ps.ps_supplycost) AS min_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerSections AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(DISTINCT o.o_orderkey) AS orders_made
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey, c.c_name 
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 2
),
FinalReport AS (
    SELECT 
        n.n_name,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        COUNT(DISTINCT co.o_orderkey) AS total_orders,
        COUNT(DISTINCT c.c_custkey) AS unique_customers,
        STRING_AGG(DISTINCT p.p_name, ', ') AS product_names
    FROM 
        lineitem li
    INNER JOIN 
        orders co ON li.l_orderkey = co.o_orderkey
    INNER JOIN 
        customer c ON co.o_custkey = c.c_custkey
    INNER JOIN 
        partsupp ps ON li.l_partkey = ps.ps_partkey
    INNER JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    INNER JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        li.l_shipdate < CURRENT_DATE - INTERVAL '30 days' 
        AND (li.l_returnflag IS NULL OR li.l_returnflag <> 'R')
    GROUP BY 
        n.n_name
)
SELECT 
    fr.n_name, 
    fr.total_sales, 
    fr.total_orders, 
    fr.unique_customers,
    AVG(fo.totalprice) AS avg_order_total
FROM 
    FinalReport fr
LEFT JOIN 
    RankedOrders fo ON fr.n_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = (SELECT DISTINCT co.o_custkey FROM orders co WHERE co.o_orderkey = fo.o_orderkey LIMIT 1)))
GROUP BY 
    fr.n_name
HAVING 
    fr.total_sales > (SELECT AVG(total_sales) FROM FinalReport) OR (SUM(fr.total_orders) IS NULL AND AVEL((SELECT SUM(fr.total_orders) FROM FinalReport)) IS NOT NULL)
ORDER BY 
    fr.total_sales DESC, 
    fr.unique_customers DESC;
