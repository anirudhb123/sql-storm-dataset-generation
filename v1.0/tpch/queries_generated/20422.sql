WITH RankedSuppliers AS (
    SELECT 
        ps_partkey, 
        ps_suppkey, 
        ps_availqty, 
        ps_supplycost, 
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS supplier_rank
    FROM 
        partsupp
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'P') 
        AND c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_mktsegment = c.c_mktsegment)
    GROUP BY 
        c.c_custkey
),
HighDemandLines AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_quantity) AS total_quantity 
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
    HAVING 
        SUM(l.l_quantity) > 100
),
SupplierData AS (
    SELECT 
        s.s_suppkey, 
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    LEFT JOIN 
        RankedSuppliers ps ON s.s_suppkey = ps.ps_suppkey AND ps.supplier_rank = 1
    GROUP BY 
        s.s_suppkey
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT c_orders.c_custkey) AS unique_customers,
    SUM(sd.total_supplycost) AS aggregate_cost,
    AVG(sd.unique_parts) AS avg_parts_per_supplier
FROM 
    nation n
LEFT JOIN 
    CustomerOrders c_orders ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey IN (SELECT o.o_custkey FROM orders o))
LEFT JOIN 
    SupplierData sd ON sd.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size IS NULL OR p.p_size > 10))
WHERE 
    n.n_comment IS NOT NULL AND LENGTH(n.n_comment) > 50
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c_orders.c_custkey) > 5
ORDER BY 
    nation DESC
UNION ALL
SELECT 
    'GLOBAL' AS nation, 
    COUNT(DISTINCT c_orders.c_custkey) AS unique_customers, 
    SUM(sd.total_supplycost) AS aggregate_cost,
    AVG(sd.unique_parts) AS avg_parts_per_supplier
FROM 
    SupplierData sd
LEFT JOIN 
    CustomerOrders c_orders ON sd.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_availqty IS NOT NULL AND ps.ps_supplycost < 100)
WHERE 
    sd.unique_parts > 0
ORDER BY 
    unique_customers DESC;
