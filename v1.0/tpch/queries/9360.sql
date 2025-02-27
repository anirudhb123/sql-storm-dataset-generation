WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        rc.total_spent,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        RankedCustomers rc
    JOIN 
        customer c ON rc.c_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rc.rank_spent <= 10
),
PartSupplierStats AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    tc.c_name,
    tc.total_spent,
    tc.nation_name,
    tc.region_name,
    ps.supplier_count,
    ps.avg_supply_cost
FROM 
    TopCustomers tc
JOIN 
    PartSupplierStats ps ON ps.ps_partkey = (SELECT l.l_partkey 
                                               FROM lineitem l 
                                               JOIN orders o ON l.l_orderkey = o.o_orderkey 
                                               WHERE o.o_custkey = tc.c_custkey 
                                               ORDER BY l.l_extendedprice DESC 
                                               LIMIT 1)
ORDER BY 
    tc.total_spent DESC;