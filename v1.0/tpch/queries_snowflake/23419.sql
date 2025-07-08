WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
), 
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty, 
        ps.ps_supplycost,
        (SELECT COUNT(*) 
         FROM lineitem l 
         WHERE l.l_partkey = ps.ps_partkey 
           AND l.l_discount > 0.1) AS high_discount_count,
        (SELECT SUM(l.l_extendedprice) 
         FROM lineitem l 
         WHERE l.l_partkey = ps.ps_partkey 
           AND l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31') AS total_sales_1996
    FROM 
        partsupp ps
), 
CustomerOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderstatus
), 
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY n.n_name) AS nation_rank
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), 
SupplierStats AS (
    SELECT 
        ns.n_name, 
        SUM(p.ps_supplycost * p.ps_availqty) AS total_supply_cost
    FROM 
        PartSupplierDetails p
    JOIN 
        RankedSuppliers s ON p.ps_suppkey = s.s_suppkey
    JOIN 
        NationRegion ns ON s.s_nationkey = ns.n_nationkey
    GROUP BY 
        ns.n_name
)

SELECT 
    cs.o_orderkey,
    cs.total_price,
    coalesce(ns.n_name, 'Unknown') AS nation_name,
    ss.total_supply_cost,
    (SELECT AVG(total_supply_cost) FROM SupplierStats) AS avg_supply_cost,
    CASE WHEN cs.item_count > 10 THEN 'Bulk'
         WHEN cs.item_count BETWEEN 5 AND 10 THEN 'Medium'
         ELSE 'Small' END AS order_size_category
FROM 
    CustomerOrders cs
LEFT JOIN 
    SupplierStats ss ON ss.total_supply_cost > 1000
LEFT JOIN 
    NationRegion ns ON cs.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = ns.n_nationkey FETCH FIRST 1 ROW ONLY)
WHERE 
    cs.o_orderstatus = 'O'
AND (cs.total_price IS NOT NULL OR ss.total_supply_cost IS NULL)
ORDER BY 
    cs.total_price DESC,
    cs.o_orderkey
LIMIT 50;