WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        c.c_name,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
),
TopOrders AS (
    SELECT *
    FROM RankedOrders
    WHERE order_rank <= 5
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
FinalResults AS (
    SELECT 
        t.o_orderkey,
        t.o_orderstatus,
        t.o_totalprice,
        t.o_orderdate,
        t.o_orderpriority,
        t.c_name,
        t.nation_name,
        s.total_supply_cost
    FROM 
        TopOrders t
    JOIN 
        SupplierCosts s ON s.ps_partkey IN (
        SELECT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey = t.o_orderkey
    )
)
SELECT 
    nation_name,
    COUNT(o.o_orderkey) AS orders_count,
    AVG(o.o_totalprice) AS average_order_value,
    SUM(s.total_supply_cost) AS total_supply_costs
FROM 
    FinalResults o
JOIN 
    SupplierCosts s ON s.ps_partkey IN (
        SELECT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey = o.o_orderkey
    )
GROUP BY 
    nation_name
ORDER BY 
    orders_count DESC,
    average_order_value DESC;
