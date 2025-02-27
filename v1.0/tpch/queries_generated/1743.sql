WITH SupplierStats AS (
    SELECT 
        s.n_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.n_nationkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2021-01-01' AND o.o_orderdate <= DATE '2021-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
        COALESCE(os.total_price, 0) AS total_order_value
    FROM 
        nation n
    LEFT JOIN 
        SupplierStats ss ON n.n_nationkey = ss.n_nationkey
    LEFT JOIN 
        OrderStats os ON n.n_nationkey = os.o_orderkey
)
SELECT 
    ns.n_name,
    ns.total_supply_cost,
    ns.total_order_value,
    CASE 
        WHEN ns.total_supply_cost > 0 THEN ns.total_order_value / ns.total_supply_cost 
        ELSE NULL 
    END AS cost_to_order_ratio,
    ROW_NUMBER() OVER (ORDER BY ns.total_order_value DESC) AS rank
FROM 
    NationStats ns
WHERE 
    (ns.total_supply_cost IS NULL OR ns.total_supply_cost > 10000)
ORDER BY 
    ns.n_name;
