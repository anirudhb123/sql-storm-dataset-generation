
WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_mktsegment = 'AUTO')
),
AggregatedOrders AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        SUM(co.o_totalprice) AS total_spent,
        COUNT(co.o_orderkey) AS order_count
    FROM 
        CustomerOrders co
    WHERE 
        co.rn <= 5
    GROUP BY 
        co.c_custkey, co.c_name
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
RegionSuppliers AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_nationkey, r.r_regionkey
)
SELECT 
    ao.c_custkey,
    ao.c_name,
    ao.total_spent,
    rs.supplier_count,
    sd.total_available,
    sd.avg_supply_cost
FROM 
    AggregatedOrders ao
LEFT JOIN 
    RegionSuppliers rs ON ao.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = rs.r_regionkey) LIMIT 1)
LEFT JOIN 
    SupplierDetails sd ON sd.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = ao.c_custkey))
WHERE 
    ao.total_spent > (SELECT AVG(total_spent) FROM AggregatedOrders)
ORDER BY 
    ao.total_spent DESC
LIMIT 10;
