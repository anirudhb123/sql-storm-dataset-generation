WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice
    FROM part p
    WHERE p.p_retailprice > (
        SELECT AVG(p1.p_retailprice) 
        FROM part p1
    )
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        H.p_name
    FROM partsupp ps
    JOIN HighValueParts H ON ps.ps_partkey = H.p_partkey
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY o.o_orderkey, c.c_custkey
)
SELECT 
    C.cust_name,
    S.s_name,
    P.p_name,
    COALESCE(SP.ps_availqty, 0) AS available_quantity,
    COALESCE(AVG(SP.ps_supplycost), 0) AS avg_supply_cost,
    R.r_name AS region_name,
    COUNT(DISTINCT O.o_orderkey) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY C.c_custkey ORDER BY O.o_orderdate DESC) AS order_rank
FROM CustomerOrders O
JOIN customer C ON O.c_custkey = C.c_custkey
LEFT JOIN supplier_part_details SP ON SP.ps_suppkey = (
        SELECT s.s_suppkey FROM RankedSuppliers s 
        WHERE s.rn = 1 AND C.c_nationkey = s.n_nationkey
        LIMIT 1
    )
LEFT JOIN part P ON SP.ps_partkey = P.p_partkey
LEFT JOIN nation N ON C.c_nationkey = N.n_nationkey
LEFT JOIN region R ON N.n_regionkey = R.r_regionkey
GROUP BY C.cust_name, S.s_name, P.p_name, R.r_name
HAVING COALESCE(order_count, 0) > (
    SELECT COUNT(DISTINCT o2.o_orderkey)
    FROM orders o2
    WHERE o2.o_orderstatus = 'F'
) 
ORDER BY order_count DESC, P.p_retailprice ASC
LIMIT 100;
