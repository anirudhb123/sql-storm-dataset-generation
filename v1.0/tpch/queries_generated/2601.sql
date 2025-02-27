WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_custkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        c.c_acctbal
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cd.c_name,
    cd.nation_name,
    cd.region_name,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(ro.o_totalprice) AS total_spent,
    SUM(sp.total_availqty) AS total_available_parts,
    AVG(sp.avg_supplycost) AS average_supply_cost,
    CASE 
        WHEN SUM(sp.total_availqty) IS NULL 
        THEN 'No Parts Available' 
        ELSE 'Parts Available'
    END AS part_availability,
    MAX(ro.o_orderdate) AS last_order_date
FROM 
    CustomerDetails cd
LEFT JOIN 
    RankedOrders ro ON cd.c_custkey = ro.o_custkey
LEFT JOIN 
    SupplierParts sp ON ro.o_orderkey IN (
        SELECT DISTINCT l.l_orderkey
        FROM lineitem l
        WHERE l.l_returnflag = 'N'
    )
WHERE 
    cd.c_acctbal > (
        SELECT AVG(c_acctbal) * 0.5 FROM customer
    )
GROUP BY 
    cd.c_name, cd.nation_name, cd.region_name
HAVING 
    COUNT(DISTINCT ro.o_orderkey) > 5
ORDER BY 
    total_spent DESC;
