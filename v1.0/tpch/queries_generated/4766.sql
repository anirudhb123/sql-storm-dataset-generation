WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s_acctbal) 
            FROM supplier 
            WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_comment LIKE '%Supplier%')
        )
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FrequentItems AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
    HAVING 
        SUM(l.l_quantity) > (
            SELECT AVG(SUM(l2.l_quantity)) 
            FROM lineitem l2 
            GROUP BY l2.l_partkey
        )
)
SELECT 
    R.n_name AS nation_name,
    COALESCE(S.s_name, 'No Supplier') AS supplier_name,
    C.total_orders,
    C.total_spent,
    F.total_quantity
FROM 
    nation R
LEFT JOIN 
    RankedSuppliers S ON R.n_nationkey = (SELECT n_regionkey FROM region WHERE r_name = 'AMERICA')
LEFT JOIN 
    CustomerOrders C ON C.c_custkey = (SELECT c_custkey FROM customer ORDER BY c_acctbal DESC LIMIT 1)
LEFT JOIN 
    FrequentItems F ON F.l_partkey = (SELECT p_partkey FROM part ORDER BY p_retailprice DESC LIMIT 1)
WHERE 
    (C.total_orders > 5 OR C.total_spent IS NOT NULL)
    AND (S.rank IS NULL OR S.rank = 1);
