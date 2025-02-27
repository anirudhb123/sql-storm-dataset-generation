WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE
        o.o_orderdate >= DATE '2022-01-01' AND 
        o.o_orderdate < DATE '2023-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2022-01-01'
    GROUP BY 
        l.l_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        supplier s
    JOIN 
        lineitem l ON s.s_suppkey = l.l_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(l.l_quantity) > 10000
)
SELECT 
    n.n_name AS nation,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    COALESCE(SUM(r.total_supply_cost), 0) AS total_supply_cost,
    AVG(o.o_totalprice) AS avg_order_price,
    COUNT(DISTINCT os.o_orderkey) AS order_count,
    CASE 
        WHEN COUNT(DISTINCT os.o_orderkey) IS NULL THEN 'No Orders'
        WHEN COUNT(DISTINCT os.o_orderkey) = 0 THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierParts r ON r.ps_partkey IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost > 0 AND ps.ps_availqty IS NOT NULL)
LEFT JOIN 
    RankedOrders os ON os.o_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o WHERE o.o_orderkey IS NOT NULL AND o.o_orderstatus = 'F' AND os.o_orderdate = o.o_orderdate)
LEFT JOIN 
    HighValueSales hvs ON hvs.l_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_returnflag = 'R')
JOIN 
    parts p ON p.p_partkey = r.ps_partkey
WHERE 
    n.n_nationkey IS NOT NULL AND 
    (s.s_acctbal > 5000 OR s.s_acctbal IS NULL)
GROUP BY 
    n.n_name
ORDER BY 
    total_supply_cost DESC, avg_order_price ASC
FETCH FIRST 10 ROWS ONLY;
