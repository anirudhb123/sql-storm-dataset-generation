WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
NationSuppliers AS (
    SELECT 
        n.n_name,
        SUM(s.s_acctbal) AS total_acctbal,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        CASE 
            WHEN o.o_orderstatus = 'O' THEN 'Open'
            WHEN o.o_orderstatus = 'F' THEN 'Finished'
            ELSE 'Unknown'
        END AS order_status
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
LineitemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) FILTER (WHERE l.l_returnflag = 'R') AS returns_count
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY l.l_orderkey
)
SELECT 
    ns.n_name AS nation_name,
    ns.total_acctbal AS total_account_balance,
    AVG(COALESCE(rp.p_retailprice, 0)) AS avg_retail_price,
    COALESCE(SUM(ls.total_revenue), 0) AS total_revenue,
    COUNT(co.o_orderkey) AS total_orders,
    MAX(co.o_totalprice) AS max_order_value
FROM NationSuppliers ns
LEFT JOIN RankedParts rp ON CHARINDEX('A', rp.p_brand) > 0
LEFT JOIN CustomerOrders co ON ns.n_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = co.c_nationkey)
LEFT JOIN LineitemStats ls ON ls.l_orderkey = co.o_orderkey
GROUP BY ns.n_name, ns.total_acctbal
HAVING COUNT(co.o_orderkey) > 5
ORDER BY total_account_balance DESC, nation_name ASC;
