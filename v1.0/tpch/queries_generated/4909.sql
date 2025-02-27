WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'P')
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        IFNULL(sp.total_availqty, 0) AS total_availqty,
        IFNULL(sp.supplier_count, 0) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        SupplierParts sp ON p.p_partkey = sp.ps_partkey
)
SELECT 
    n.n_name,
    pd.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(pd.p_retailprice) AS avg_price,
    COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count
FROM 
    lineitem l
JOIN 
    RankedOrders ro ON l.l_orderkey = ro.o_orderkey
JOIN 
    PartDetails pd ON l.l_partkey = pd.p_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    pd.total_availqty > 0 
    AND pd.supplier_count > 1
    AND ro.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
GROUP BY 
    n.n_name, pd.p_name
ORDER BY 
    revenue DESC, n.n_name, pd.p_name;
