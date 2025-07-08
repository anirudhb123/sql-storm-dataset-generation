
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
), 
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
    GROUP BY 
        p.p_partkey, p.p_name
), 
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
), 
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(*) AS lineitem_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipmode IN ('AIR', 'SEA') 
        AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name,
    COALESCE(SUM(r.s_acctbal), 0) AS total_supplier_balance,
    COALESCE(SUM(hp.total_cost), 0) AS total_high_value_part_cost,
    COALESCE(SUM(f.net_revenue), 0) AS total_net_revenue,
    COUNT(DISTINCT ro.o_orderkey) AS total_recent_orders
FROM 
    nation n
LEFT JOIN 
    RankedSuppliers r ON n.n_nationkey = r.s_suppkey
LEFT JOIN 
    HighValueParts hp ON hp.p_partkey IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = r.s_suppkey)
LEFT JOIN 
    FilteredLineItems f ON f.l_orderkey IN (SELECT o.o_orderkey FROM RecentOrders o WHERE o.o_custkey = r.s_suppkey)
LEFT JOIN 
    RecentOrders ro ON ro.o_custkey = r.s_suppkey AND ro.o_orderdate = (SELECT MAX(o2.o_orderdate) FROM orders o2 WHERE o2.o_custkey = r.s_suppkey)
WHERE 
    r.rn <= 5
GROUP BY 
    n.n_name, r.s_suppkey, r.s_name, r.s_acctbal
ORDER BY 
    total_supplier_balance DESC
LIMIT 10;
