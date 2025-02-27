WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
NationDetails AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 10000
    GROUP BY 
        c.c_custkey
)

SELECT 
    od.n_name AS nation_name,
    od.region_name,
    ca.total_spent,
    ca.order_count,
    SUM(la.l_extendedprice * (1 - la.l_discount)) AS total_revenue,
    COUNT(DISTINCT la.l_linenumber) AS item_count,
    COALESCE(SUM(sa.total_avail_qty), 0) AS total_available_quantity,
    AVG(sa.avg_supply_cost) OVER (PARTITION BY od.n_nationkey) AS avg_supply_cost
FROM 
    CustomerOrders ca
JOIN 
    CustomerDetails od ON ca.c_custkey = od.c_custkey
LEFT JOIN 
    lineitem la ON la.l_orderkey IN (SELECT o_orderkey FROM RankedOrders WHERE order_rank <= 10)
LEFT JOIN 
    SupplierAvailability sa ON la.l_partkey = sa.ps_partkey
JOIN 
    NationDetails nd ON od.n_nationkey = nd.n_nationkey
GROUP BY 
    od.n_name, od.region_name, ca.total_spent, ca.order_count
ORDER BY 
    total_revenue DESC
LIMIT 50;
