WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        n.n_name AS nation_name
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    WHERE 
        ro.order_rank <= 5
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        pc.total_supply_cost,
        COALESCE(pc.total_supply_cost, 0) AS supply_cost_with_nulls
    FROM 
        part p
    LEFT JOIN 
        SupplierCost pc ON p.p_partkey = pc.ps_partkey
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.o_totalprice,
    pd.p_name,
    pd.p_retailprice,
    pd.total_supply_cost,
    pd.supply_cost_with_nulls,
    (CASE 
        WHEN pd.supply_cost_with_nulls IS NULL THEN 'No Supply Cost'
        ELSE 'Supply Cost Present'
    END) AS Supply_Cost_Status
FROM 
    TopOrders to
JOIN 
    lineitem li ON to.o_orderkey = li.l_orderkey
JOIN 
    PartDetails pd ON li.l_partkey = pd.p_partkey
WHERE 
    to.o_totalprice > 1000
ORDER BY 
    to.o_orderdate DESC, to.o_orderkey ASC
