WITH RankedSupplies AS (
    SELECT 
        ps_partkey, 
        ps_suppkey, 
        ps_availqty, 
        ps_supplycost,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS supply_rank
    FROM 
        partsupp
    WHERE 
        ps_availqty > 0
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS item_count,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N' AND 
        l.l_shipdate < CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name
),
AggregateData AS (
    SELECT 
        od.o_orderkey,
        od.item_count,
        CASE 
            WHEN od.total_revenue > 10000 THEN 'High Value' 
            ELSE 'Low Value' 
        END AS order_value_category
    FROM 
        OrderDetails od
    WHERE 
        od.total_revenue IS NOT NULL AND 
        od.item_count > 0
)
SELECT 
    ps.ps_partkey,
    ps.ps_suppkey,
    COALESCE(rd.supply_rank, 0) AS supply_rank,
    sd.total_supply_cost,
    ad.order_value_category,
    COUNT(DISTINCT ad.o_orderkey) AS order_count
FROM 
    RankedSupplies rd
FULL OUTER JOIN 
    SupplierDetails sd ON rd.ps_suppkey = sd.s_suppkey
LEFT JOIN 
    AggregateData ad ON ad.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_custkey IN (
            SELECT c.c_custkey 
            FROM customer c 
            WHERE c.c_acctbal > 0 OR c.c_acctbal IS NULL
        )
    )
GROUP BY 
    ps.ps_partkey, ps.ps_suppkey, sd.total_supply_cost, ad.order_value_category, rd.supply_rank
HAVING 
    sd.total_supply_cost > 5000 OR 
    ad.order_value_category = 'High Value'
ORDER BY 
    sd.region_name, supply_rank DESC, order_count DESC;
