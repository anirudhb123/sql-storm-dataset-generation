WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        CONCAT(s.s_name, ' located in ', s.s_address, '; Nation: ', n.n_name, '; Region: ', r.r_name) AS full_info
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
), 
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        CONCAT(p.p_name, ' [', p.p_brand, ']', ' Type: ', p.p_type, ' Size: ', p.p_size) AS part_info
    FROM part p
), 
OrderInfo AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_orderdate,
        o.o_totalprice,
        CONCAT(c.c_name, ' ordered on ', TO_CHAR(o.o_orderdate, 'YYYY-MM-DD'), ' total: $', TO_CHAR(o.o_totalprice, 'FM9999999999.00')) AS order_summary
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
LineItemDetails AS (
    SELECT 
        li.l_orderkey,
        li.l_partkey,
        li.l_suppkey,
        li.l_quantity,
        li.l_extendedprice,
        li.l_discount,
        CONCAT('OrderKey: ', li.l_orderkey, ', PartKey: ', li.l_partkey, ', Quantity: ', li.l_quantity, ', Total Price: $', TO_CHAR(li.l_extendedprice * (1 - li.l_discount), 'FM9999999999.00')) AS lineitem_info
    FROM lineitem li
)
SELECT 
    sd.full_info,
    pd.part_info,
    oi.order_summary,
    lid.lineitem_info
FROM SupplierDetails sd
JOIN PartDetails pd ON pd.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey)
JOIN OrderInfo oi ON oi.o_orderkey IN (SELECT li.l_orderkey FROM lineitem li WHERE li.l_partkey = pd.p_partkey)
JOIN LineItemDetails lid ON lid.l_orderkey = oi.o_orderkey AND lid.l_partkey = pd.p_partkey
ORDER BY sd.s_suppkey, oi.o_orderdate DESC;
