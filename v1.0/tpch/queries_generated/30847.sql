WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierAvailability AS (
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
NotableParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 1
),
HighValueCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent
    FROM 
        CustomerOrders co
    WHERE 
        co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
RegionNation AS (
    SELECT 
        n.n_nationkey,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    nv.p_partkey,
    nv.p_name,
    nv.p_brand,
    nv.p_retailprice,
    COALESCE(hv.total_spent, 0) AS high_value_spent,
    rn.region_name,
    rn.nation_name
FROM 
    NotableParts nv
LEFT JOIN 
    HighValueCustomers hv ON nv.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN 
        (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')))
LEFT JOIN 
    RegionNation rn ON nv.p_partkey IN (SELECT li.l_partkey FROM lineitem li WHERE li.l_orderkey IN 
        (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = hv.c_custkey))
ORDER BY 
    nv.p_retailprice DESC, high_value_spent DESC;
