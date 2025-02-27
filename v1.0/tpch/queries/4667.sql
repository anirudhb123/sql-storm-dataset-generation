WITH SupplierStats AS (
    SELECT 
        s_nationkey,
        COUNT(DISTINCT s_suppkey) AS unique_suppliers,
        SUM(s_acctbal) AS total_acctbal
    FROM 
        supplier
    GROUP BY 
        s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierCosts AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
)

SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT ns.n_nationkey) AS nation_count,
    COALESCE(SUM(ss.unique_suppliers), 0) AS total_unique_suppliers,
    COALESCE(SUM(co.total_spent), 0) AS total_customer_spent,
    AVG(p.total_cost) AS avg_part_supplier_cost
FROM 
    region r
LEFT JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    SupplierStats ss ON ns.n_nationkey = ss.s_nationkey
LEFT JOIN 
    CustomerOrders co ON ns.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = co.c_custkey)
LEFT JOIN 
    PartSupplierCosts p ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = ns.n_nationkey) LIMIT 1)
GROUP BY 
    r.r_name
HAVING
    COUNT(DISTINCT ns.n_nationkey) > 1
ORDER BY 
    total_customer_spent DESC;