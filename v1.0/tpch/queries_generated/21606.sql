WITH RecursiveNations AS (
    SELECT n_nationkey, n_name, n_regionkey
    FROM nation
    WHERE n_nationkey IS NOT NULL
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey
    FROM nation n
    JOIN RecursiveNations r ON n.n_regionkey = r.n_regionkey
),

SupplierCost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),

RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F') 
),

CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2) 
            THEN 'Above Average'
            ELSE 'Below Average'
        END AS balance_category
    FROM customer c
),

PartSupplierCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)

SELECT 
    p.p_name, 
    ns.n_name AS nation_name,
    c.c_name AS customer_name,
    rc.total_supplycost,
    RANK() OVER (ORDER BY pc.supplier_count DESC) AS part_rank,
    CASE 
        WHEN MAX(o.o_orderpriority) IS NULL 
        THEN 'No Orders'
        ELSE MAX(o.o_orderpriority)
    END AS max_order_priority,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END), 0) AS total_returns
FROM part p
JOIN partSupplierCount pc ON p.p_partkey = pc.ps_partkey
LEFT JOIN supplier s ON pc.ps_partkey = s.s_suppkey
JOIN RecursiveNations ns ON s.s_nationkey = ns.n_nationkey
LEFT JOIN CustomerDetails c ON ns.n_regionkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
GROUP BY p.p_name, ns.n_name, c.c_name
HAVING SUM(l.l_extendedprice) IS NOT NULL OR MAX(c.c_acctbal) IS NULL
ORDER BY part_rank, nation_name;
