WITH RECURSIVE CustomerOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) as order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_extendedprice,
        l.l_discount,
        l.l_shipdate,
        SUM(l.l_quantity) OVER (PARTITION BY l.l_orderkey) AS total_quantity
    FROM 
        lineitem l
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        n.n_name || ' (' || r.r_name || ')' AS nation_region
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    co.o_orderkey,
    co.o_orderdate,
    co.o_totalprice,
    co.c_name,
    ss.total_supply_cost,
    ss.parts_supplied,
    lid.l_extendedprice,
    lid.l_discount,
    lid.total_quantity,
    nr.nation_region
FROM 
    CustomerOrders co
LEFT JOIN 
    LineItemDetails lid ON co.o_orderkey = lid.l_orderkey
LEFT JOIN 
    SupplierStats ss ON lid.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ss.s_suppkey)
INNER JOIN 
    NationRegion nr ON lid.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderkey = co.o_orderkey)
WHERE 
    co.order_rank = 1 
    AND co.o_totalprice > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderdate > '2023-01-01')
ORDER BY 
    co.o_orderdate DESC, 
    co.o_totalprice DESC;
