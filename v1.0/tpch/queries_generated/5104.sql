WITH RankedOrders AS (
    SELECT 
        o_orderkey,
        o_custkey,
        o_orderdate,
        o_totalprice,
        RANK() OVER (PARTITION BY o_custkey ORDER BY o_totalprice DESC) AS price_rank
    FROM 
        orders
    WHERE 
        o_orderdate BETWEEN '2022-01-01' AND '2023-12-31'
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(DISTINCT ro.o_orderkey) AS total_orders,
        SUM(ro.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        RankedOrders ro ON c.c_custkey = ro.o_custkey
    WHERE 
        ro.price_rank <= 5
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
),
SupplierStats AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_suppkey
),
FinalReport AS (
    SELECT 
        tc.c_custkey,
        tc.c_name,
        tc.total_orders,
        tc.total_spent,
        ss.total_available_quantity,
        ss.average_supply_cost
    FROM 
        TopCustomers tc
    JOIN 
        SupplierStats ss ON ss.ps_suppkey IN (
            SELECT ps.ps_suppkey 
            FROM partsupp ps 
            JOIN lineitem li ON ps.ps_partkey = li.l_partkey 
            WHERE li.l_orderkey IN (SELECT o_orderkey FROM RankedOrders)
        )
)
SELECT 
    * 
FROM 
    FinalReport
WHERE 
    total_spent > 50000
ORDER BY 
    total_spent DESC, total_orders DESC;
