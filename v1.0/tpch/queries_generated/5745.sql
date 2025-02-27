WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplied_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_linenumber) AS total_items_ordered
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(od.total_order_value) AS total_sales,
        SUM(sd.total_supplied_cost) AS total_supply_costs
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        CustomerOrderDetails od ON c.c_custkey = od.o_custkey
    JOIN 
        SupplierDetails sd ON sd.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN lineitem l ON ps.ps_partkey = l.l_partkey WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey))
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    n.n_name,
    n.total_sales,
    n.total_supply_costs,
    CASE 
        WHEN n.total_sales > n.total_supply_costs THEN 'Profitable'
        ELSE 'Loss'
    END AS profitability_status
FROM 
    NationSummary n
ORDER BY 
    n.total_sales DESC;
