WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate > DATEADD(month, -3, GETDATE())
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        n.n_name,
        r.r_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), 
PartSupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_size,
    p.p_retailprice,
    ps.total_avail_qty,
    ps.avg_supply_cost,
    sd.s_name AS primary_supplier,
    sd.n_name AS supplier_nation,
    rd.o_orderkey,
    rd.o_orderstatus,
    rd.o_totalprice,
    rd.o_orderdate
FROM 
    part p
LEFT JOIN 
    PartSupplierStats ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierDetails sd ON ps.unique_suppliers = (SELECT COUNT(*) FROM supplier s WHERE s.s_suppkey = sd.s_suppkey)
LEFT JOIN 
    RankedOrders rd ON rd.o_orderkey = (SELECT TOP 1 o_orderkey FROM orders WHERE o_orderstatus = 'O' ORDER BY o_orderdate DESC)
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size BETWEEN 10 AND 20)
AND 
    (SELECT COUNT(*) FROM lineitem l WHERE l.l_partkey = p.p_partkey AND l.l_returnflag = 'R') = 0
ORDER BY 
    p.p_partkey, rd.o_orderdate DESC
OPTION (MAXDOP = 1);
