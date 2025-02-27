WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_custkey
),
CustomerRank AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COALESCE(SUM(r.total_revenue), 0) AS total_spent,
        RANK() OVER (ORDER BY COALESCE(SUM(r.total_revenue), 0) DESC) AS cust_rank
    FROM 
        customer c
    LEFT JOIN 
        RankedOrders r ON c.c_custkey = r.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name,
        n.n_name AS nation_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    CONCAT(c.c_name, ' (', cr.cust_rank, ')') AS customer_details,
    sp.p_name AS part_name,
    sp.ps_availqty,
    sp.ps_supplycost,
    sh.level AS supplier_level,
    COALESCE(cr.total_spent, 0) AS total_spent_by_customer
FROM 
    SupplierPartDetails sp
JOIN 
    CustomerRank cr ON sp.ps_supplycost IN (SELECT DISTINCT ps_supplycost FROM partsupp WHERE ps_availqty > 0)
JOIN 
    SupplierHierarchy sh ON sp.nation_name = sh.s_nationkey
WHERE 
    cr.cust_rank <= 5
ORDER BY 
    total_spent_by_customer DESC, supplier_level ASC;
