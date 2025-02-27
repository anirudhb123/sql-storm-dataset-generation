WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_address, s.s_phone
    HAVING COUNT(DISTINCT ps.ps_partkey) > 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS line_item_count,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returns_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
),
SalesSummary AS (
    SELECT 
        r.r_name,
        SUM(co.o_totalprice) AS total_sales,
        COUNT(DISTINCT co.c_custkey) AS unique_customers,
        SUM(CASE WHEN co.returns_count > 0 THEN 1 ELSE 0 END) AS total_returns
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustomerOrders co ON o.o_orderkey = co.o_orderkey
    GROUP BY r.r_name
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    ts.s_name AS supplier_name,
    ss.total_sales,
    ss.unique_customers,
    ss.total_returns
FROM RankedParts rp
JOIN TopSuppliers ts ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey)
JOIN SalesSummary ss ON EXISTS (SELECT 1 FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey WHERE o.o_orderstatus = 'O')
WHERE rp.rank <= 3
ORDER BY ss.total_sales DESC, rp.p_retailprice DESC;
