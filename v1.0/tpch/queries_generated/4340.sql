WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    co.c_custkey,
    co.c_name,
    nr.r_name AS region,
    COUNT(DISTINCT co.o_orderkey) AS order_count,
    SUM(co.total_sales) AS total_sales,
    MAX(RS.s_acctbal) AS max_account_balance,
    AVG(SP.avg_supply_cost) AS average_supply_cost,
    (SELECT COUNT(*)
     FROM partsupp p
     WHERE p.ps_availqty = (SELECT MAX(ps.ps_availqty) FROM partsupp ps)) AS max_available_parts
FROM 
    CustomerOrders co
LEFT JOIN 
    NationRegion nr ON co.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = nr.n_nationkey)
LEFT JOIN 
    RankedSuppliers RS ON RS.rnk = 1 AND RS.s_suppkey = (SELECT ps.ps_suppkey FROM SupplierParts ps WHERE ps.ps_partkey IN (SELECT DISTINCT l.l_partkey FROM lineitem l WHERE l.l_returnflag = 'R'))
LEFT JOIN 
    SupplierParts SP ON SP.ps_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = co.o_orderkey LIMIT 1)
WHERE 
    co.total_sales > 10000
GROUP BY 
    co.c_custkey, co.c_name, nr.r_name
ORDER BY 
    total_sales DESC;
