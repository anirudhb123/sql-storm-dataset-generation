
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank,
        o.o_custkey
    FROM 
        orders o
    WHERE 
        o.o_orderdate > DATE '1998-10-01' - INTERVAL '1 year'
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(ro.o_orderkey) AS order_count,
        SUM(ro.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        RankedOrders ro ON ro.o_custkey = c.c_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.order_count,
    co.total_spent,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_acctbal AS supplier_balance
FROM 
    CustomerOrders co
JOIN 
    supplier s ON s.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_type = 'Widget'
        )
        LIMIT 1
    )
JOIN 
    nation n ON n.n_nationkey = (
        SELECT c.c_nationkey 
        FROM customer c 
        WHERE c.c_custkey = co.c_custkey
    )
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
WHERE 
    co.total_spent > (
        SELECT AVG(total_spent) 
        FROM CustomerOrders
    )
ORDER BY 
    co.total_spent DESC
LIMIT 100;
