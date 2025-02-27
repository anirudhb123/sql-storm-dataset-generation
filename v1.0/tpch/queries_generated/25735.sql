WITH 
    SupplierDetails AS (
        SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
        FROM supplier s
        JOIN nation n ON s.s_nationkey = n.n_nationkey
        WHERE s.s_acctbal > (
            SELECT AVG(s2.s_acctbal)
            FROM supplier s2
            WHERE s2.s_nationkey = s.s_nationkey
        )
    ),
    PartDetails AS (
        SELECT p.p_partkey, p.p_name, p.p_brand, ps.ps_availqty, ps.ps_supplycost
        FROM part p
        JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
        WHERE p.p_brand LIKE 'Brand%1'
    ),
    OrderDetails AS (
        SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, 
               COUNT(li.l_orderkey) AS item_count
        FROM orders o
        JOIN lineitem li ON o.o_orderkey = li.l_orderkey
        GROUP BY o.o_orderkey, o.o_orderstatus, o.o_totalprice
        HAVING COUNT(li.l_orderkey) > 5
    )

SELECT 
    sd.s_name,
    sd.nation_name,
    pd.p_name,
    od.o_orderkey,
    od.o_totalprice,
    od.item_count,
    sd.s_acctbal,
    CONCAT('Order ', od.o_orderkey, ' contains ', od.item_count, ' items from supplier ', sd.s_name) AS order_summary
FROM 
    SupplierDetails sd
JOIN 
    PartDetails pd ON sd.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey
            FROM part p
            WHERE p.p_brand LIKE '%2%'
        )
    )
JOIN 
    OrderDetails od ON od.o_orderkey IN (
        SELECT li.l_orderkey
        FROM lineitem li
        WHERE li.l_suppkey IN (sd.s_suppkey)
    )
ORDER BY 
    sd.s_acctbal DESC, od.o_totalprice DESC;
