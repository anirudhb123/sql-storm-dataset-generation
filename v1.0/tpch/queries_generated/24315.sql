WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate < CURRENT_DATE)
), 
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_name
), 
CustomerNation AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        n.n_name IS NOT NULL
), 
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        CASE 
            WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE l.l_extendedprice 
        END AS adjusted_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATEADD(MONTH, -6, CURRENT_DATE) AND CURRENT_DATE
)

SELECT 
    cn.n_name AS nation,
    SUM(li.adjusted_price) AS total_revenue,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    AVG(sp.total_supplycost) AS avg_supply_cost
FROM 
    FilteredLineItems li
JOIN 
    RankedOrders ro ON li.l_orderkey = ro.o_orderkey
JOIN 
    SupplierPartInfo sp ON li.l_partkey = sp.ps_partkey
JOIN 
    CustomerNation cn ON ro.o_orderkey IN (SELECT l_orderkey FROM lineitem WHERE l_suppkey = sp.ps_suppkey)
GROUP BY 
    cn.n_name
HAVING 
    SUM(li.adjusted_price) > (SELECT AVG(adjusted_price) FROM FilteredLineItems)
ORDER BY 
    total_revenue DESC
LIMIT 
    10;
