WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
)
SELECT 
    cd.c_name,
    cd.nation_name,
    cd.region_name,
    ro.o_orderkey,
    ro.o_totalprice,
    COUNT(DISTINCT sp.ps_partkey) AS part_count,
    SUM(sp.total_available) AS total_available_parts,
    AVG(sp.avg_supply_cost) AS average_supply_cost,
    CASE 
        WHEN COUNT(DISTINCT sp.ps_partkey) > 0 THEN 'Available'
        ELSE 'Not Available'
    END AS availability_status
FROM 
    CustomerDetails cd
LEFT JOIN 
    RankedOrders ro ON cd.c_custkey = ro.o_custkey AND ro.OrderRank = 1
LEFT JOIN 
    SupplierParts sp ON sp.ps_partkey IN (
        SELECT DISTINCT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey = ro.o_orderkey
    )
WHERE 
    cd.c_acctbal IS NOT NULL
GROUP BY 
    cd.c_name, cd.nation_name, cd.region_name, ro.o_orderkey, ro.o_totalprice
ORDER BY 
    cd.c_name, ro.o_orderkey DESC;
