WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),
CustomerNation AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        COALESCE(MAX(s.s_acctbal), 0) AS max_acctbal
    FROM customer c
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
    GROUP BY c.c_custkey, c.c_name, n.n_name
),
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_suppkey) AS distinct_suppliers
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
JoinedData AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.total_available,
        psi.distinct_suppliers,
        cn.nation_name
    FROM part p
    JOIN PartSupplierInfo ps ON p.p_partkey = ps.ps_partkey
    JOIN CustomerNation cn ON ps.distinct_suppliers > 1
    WHERE p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2 
        WHERE p2.p_size IS NOT NULL
    )
)
SELECT 
    j.p_name,
    j.retail_price,
    j.total_available,
    j.distinct_suppliers,
    cn.nation_name,
    AVG(o.o_totalprice) AS avg_order_value
FROM JoinedData j
LEFT JOIN RankedOrders o ON o.o_orderkey IN (
    SELECT o_orderkey 
    FROM orders 
    WHERE o_orderstatus = 'O' 
      AND o_orderdate >= '2022-01-01'
)
GROUP BY 
    j.p_name, 
    j.retail_price, 
    j.total_available, 
    j.distinct_suppliers, 
    cn.nation_name
HAVING 
    COUNT(o.o_orderkey) > 2
ORDER BY 
    j.distinct_suppliers DESC, 
    j.total_available ASC
LIMIT 10;
