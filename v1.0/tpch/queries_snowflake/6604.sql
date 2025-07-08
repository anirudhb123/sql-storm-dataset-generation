WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS Rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1996-12-31'
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(r.RetailValue) AS TotalRetailValue
    FROM 
        nation n
    JOIN (
        SELECT 
            ps.ps_partkey,
            ps.ps_suppkey,
            p.p_retailprice AS RetailValue
        FROM 
            partsupp ps
        JOIN 
            part p ON ps.ps_partkey = p.p_partkey
    ) r ON r.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = n.n_nationkey)
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    rn.o_orderkey,
    rn.o_orderdate,
    rn.o_totalprice,
    rn.c_name,
    tn.n_name,
    tn.TotalRetailValue
FROM 
    RankedOrders rn
JOIN 
    customer c ON rn.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
JOIN 
    TopNations tn ON c.c_nationkey = tn.n_nationkey
WHERE 
    rn.Rank <= 10
ORDER BY 
    tn.TotalRetailValue DESC, rn.o_totalprice DESC;