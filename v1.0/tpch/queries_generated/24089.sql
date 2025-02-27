WITH RECURSIVE SupplyDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
OrderSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date,
        MIN(o.o_orderdate) AS first_order_date,
        c.c_nationkey,
        CASE 
            WHEN SUM(o.o_totalprice) > 10000 THEN 'VIP'
            WHEN SUM(o.o_totalprice) > 5000 THEN 'Regular'
            ELSE 'Occasional'
        END AS customer_type
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_nationkey
),
RegionalPerformance AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(os.total_spent) AS region_total_spent,
        COUNT(DISTINCT sd.s_suppkey) AS unique_suppliers,
        CASE 
            WHEN SUM(os.total_spent) IS NULL THEN 'No Orders'
            ELSE 'Orders Exist'
        END AS order_status
    FROM 
        nation n
    LEFT JOIN 
        OrderSummary os ON n.n_nationkey = os.c_nationkey
    LEFT JOIN 
        SupplyDetails sd ON n.n_nationkey = sd.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    rp.nation_name,
    COALESCE(rp.region_total_spent, 0) AS total_spent,
    rp.unique_suppliers,
    SUM(sd.total_supply_cost) AS total_supplier_cost,
    MAX(sd.rank) AS max_supplier_rank,
    CASE 
        WHEN rp.order_status = 'No Orders' THEN 'Nothing Ordered'
        ELSE 'Active Customers'
    END AS customer_activity
FROM 
    RegionalPerformance rp
LEFT JOIN 
    SupplyDetails sd ON rp.nation_name = sd.s_nationkey
WHERE 
    (sd.total_avail_qty IS NULL OR sd.total_avail_qty > 10) 
    AND rp.unique_suppliers >= 1
GROUP BY 
    rp.nation_name, rp.region_total_spent, rp.unique_suppliers, rp.order_status
HAVING 
    MAX(sd.s_nationkey) IS NOT NULL
ORDER BY 
    total_spent DESC, nation_name ASC;
