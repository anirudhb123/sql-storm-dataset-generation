WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 50

    UNION ALL

    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, ps2.ps_partkey, ps2.ps_availqty, ps2.ps_supplycost
    FROM supplier s2
    JOIN partsupp ps2 ON s2.s_suppkey = ps2.ps_suppkey
    JOIN SupplyChain sc ON sc.ps_partkey = ps2.ps_partkey
    WHERE ps2.ps_availqty > sc.ps_availqty
),
CustomerTotal AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
HighSpender AS (
    SELECT c.c_custkey, c.c_name, ct.total_spent
    FROM customer c
    JOIN CustomerTotal ct ON c.c_custkey = ct.c_custkey
    WHERE ct.total_spent > 10000
),
NationSupplier AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS num_suppliers
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    sc.s_suppkey, 
    sc.s_name, 
    ns.n_name AS nation_name, 
    SUM(sc.ps_supplycost) AS total_supply_cost,
    hs.total_spent,
    ROW_NUMBER() OVER (PARTITION BY ns.n_name ORDER BY SUM(sc.ps_supplycost) DESC) AS supplier_rank
FROM SupplyChain sc
JOIN NationSupplier ns ON sc.s_nationkey = ns.n_nationkey
LEFT JOIN HighSpender hs ON sc.s_suppkey = hs.c_custkey 
WHERE ns.num_suppliers > 2
GROUP BY sc.s_suppkey, sc.s_name, ns.n_name, hs.total_spent
HAVING SUM(sc.ps_supplycost) IS NOT NULL
ORDER BY nation_name, total_supply_cost DESC;
