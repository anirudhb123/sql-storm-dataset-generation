WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        CONCAT(s.s_name, ' - ', n.n_name) AS supplier_info
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ps.ps_supplycost,
        (p.p_retailprice - ps.ps_supplycost) AS profit_margin
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        (p.p_retailprice - ps.ps_supplycost) > 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
)

SELECT 
    sd.supplier_info,
    hp.p_name,
    hp.profit_margin,
    co.c_name,
    co.o_totalprice,
    co.o_orderdate
FROM 
    SupplierDetails sd
JOIN 
    HighValueParts hp ON hp.p_partkey IN (
        SELECT ps.p_partkey
        FROM partsupp ps
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE l.l_quantity > 50
    )
JOIN 
    CustomerOrders co ON co.o_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_totalprice > 500
    )
ORDER BY 
    hp.profit_margin DESC, co.o_totalprice DESC;
