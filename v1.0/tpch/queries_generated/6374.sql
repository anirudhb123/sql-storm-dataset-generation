WITH RegionSummary AS (
    SELECT 
        r.r_name AS region_name,
        SUM(s.s_acctbal) AS total_supplier_balance,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
),
PartStatistics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost,
        MAX(p.p_retailprice) AS max_retail_price
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rs.region_name,
    ps.p_name,
    cs.c_name,
    cs.total_orders,
    cs.total_spent,
    ps.total_available_quantity,
    ps.average_supply_cost,
    ps.max_retail_price,
    rs.total_supplier_balance,
    rs.unique_suppliers
FROM 
    RegionSummary rs
JOIN 
    PartStatistics ps ON ps.total_available_quantity > 100
JOIN 
    CustomerOrders cs ON cs.total_spent > 1000
WHERE 
    rs.total_supplier_balance > 50000
ORDER BY 
    rs.region_name, cs.total_spent DESC;
