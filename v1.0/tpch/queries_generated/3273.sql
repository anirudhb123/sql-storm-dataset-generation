WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-10-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 10000
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(AVG(l.l_extendedprice), 0) AS avg_extended_price,
        COUNT(l.l_orderkey) AS order_count
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        p.p_retailprice > 50.00
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        order_count > 10
)
SELECT 
    n.n_name,
    rd.o_orderkey,
    rd.o_orderdate,
    rd.o_totalprice,
    p.p_name,
    p.avg_extended_price,
    s.s_name,
    s.total_supply_cost
FROM 
    RankedOrders rd
JOIN 
    customer c ON rd.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    HighValueParts p ON p.p_partkey = (
        SELECT 
            ps.ps_partkey
        FROM 
            partsupp ps
        WHERE 
            ps.ps_price < rd.o_totalprice
        ORDER BY 
            ps.ps_availqty DESC
        LIMIT 1
    )
LEFT JOIN 
    SupplierDetails s ON s.s_suppkey = (
        SELECT 
            ps.ps_suppkey
        FROM 
            partsupp ps
        JOIN 
            part p2 ON ps.ps_partkey = p2.p_partkey
        WHERE 
            p2.p_partkey = p.p_partkey
        ORDER BY 
            ps.ps_supplycost * ps.ps_availqty DESC
        LIMIT 1
    )
WHERE 
    rd.rank <= 5
ORDER BY 
    rd.o_orderdate DESC, 
    rd.o_totalprice DESC
LIMIT 100;
