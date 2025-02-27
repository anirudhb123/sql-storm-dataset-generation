WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(SUM(ol.l_extendedprice * (1 - ol.l_discount)), 0) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem ol ON o.o_orderkey = ol.l_orderkey
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2) 
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
    HAVING COALESCE(SUM(ol.l_extendedprice * (1 - ol.l_discount)), 0) > 1000
),
ExemplaryProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    GROUP BY p.p_partkey, p.p_name
),
FinalReport AS (
    SELECT 
        hc.c_name AS customer_name,
        hp.p_name AS product_name,
        rs.s_name AS supplier_name,
        rs.s_acctbal AS supplier_acct_bal,
        hp.total_available,
        hp.avg_supply_cost,
        hc.total_spent
    FROM HighValueCustomers hc
    JOIN lineitem ol ON ol.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = hc.c_custkey)
    JOIN ExemplaryProducts hp ON hp.p_partkey = ol.l_partkey
    LEFT JOIN RankedSuppliers rs ON rs.rank = 1 AND rs.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = hp.p_partkey)
)
SELECT 
    customer_name,
    product_name,
    supplier_name,
    supplier_acct_bal,
    COALESCE(total_available, 0) AS total_available,
    COALESCE(avg_supply_cost, 0.00) AS avg_supply_cost,
    total_spent
FROM FinalReport
WHERE total_spent > (SELECT AVG(total_spent) FROM FinalReport)
ORDER BY customer_name, product_name, supplier_name;
