
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 100000
),
NationDetails AS (
    SELECT 
        n.n_name, 
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey, 
        ss.s_name,
        ss.total_available_quantity,
        ss.avg_supply_cost,
        nd.n_name,
        nd.region_name
    FROM SupplierStats ss
    JOIN NationDetails nd ON ss.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps
        WHERE ps.ps_availqty > 500
    )
),
CustomerRankings AS (
    SELECT 
        hvc.c_custkey,
        hvc.c_name,
        hvc.total_spent,
        RANK() OVER (ORDER BY hvc.total_spent DESC) AS customer_rank
    FROM HighValueCustomers hvc
)
SELECT 
    cr.c_name, 
    cr.total_spent, 
    ts.s_name AS supplier_name, 
    ts.total_available_quantity, 
    ts.avg_supply_cost, 
    ts.region_name
FROM CustomerRankings cr
FULL OUTER JOIN TopSuppliers ts ON cr.c_custkey = (
    SELECT MIN(o.o_custkey) FROM orders o WHERE o.o_orderkey = ANY(
        SELECT l.l_orderkey FROM lineitem l WHERE l.l_discount > 0.1 
    )
)
WHERE cr.customer_rank <= 10
ORDER BY cr.total_spent DESC, ts.avg_supply_cost ASC;
