WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS RankWithinNation
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        rc.c_custkey,
        rc.c_name,
        rc.TotalSpent,
        n.n_name AS Nation
    FROM RankedCustomers rc
    JOIN nation n ON rc.c_nationkey = n.n_nationkey
    WHERE rc.RankWithinNation <= 3
),
PopularParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    WHERE l.l_shipdate >= DATE '2023-01-01' 
    GROUP BY ps.ps_partkey
    ORDER BY TotalRevenue DESC
    LIMIT 5
)
SELECT 
    tc.c_name,
    tc.Nation,
    pp.p_name,
    pp.TotalRevenue
FROM TopCustomers tc
JOIN PopularParts pp ON tc.c_custkey IN (
    SELECT o.o_custkey FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE l.l_partkey = pp.ps_partkey
)
ORDER BY tc.Nation, tc.TotalSpent DESC;
