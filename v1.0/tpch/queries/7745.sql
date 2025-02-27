WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice, 
        ps.ps_availqty, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        n.n_name AS nation_name
    FROM 
        supplier s
    INNER JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        c.c_name AS customer_name, 
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_totalprice > 1000
)
SELECT 
    rp.p_name, 
    rp.p_brand, 
    rp.p_retailprice, 
    ts.s_name AS supplier_name, 
    hvo.customer_name, 
    hvo.o_orderdate,
    hvo.o_totalprice
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON rp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey LIMIT 1)
JOIN 
    lineitem li ON li.l_partkey = rp.p_partkey
JOIN 
    HighValueOrders hvo ON li.l_orderkey = hvo.o_orderkey
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.p_retailprice DESC, 
    hvo.o_orderdate ASC;
