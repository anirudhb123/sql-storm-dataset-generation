WITH SupplierParts AS (
    SELECT s.s_name, p.p_name, p.p_size, p.p_retailprice, ps.ps_availqty, 
           CONCAT(s.s_name, ' supplies ', p.p_name, ' of size ', CAST(p.p_size AS VARCHAR), 
                  ' with retail price ', CAST(p.p_retailprice AS VARCHAR), 
                  ' and available quantity ', CAST(ps.ps_availqty AS VARCHAR)) AS description
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 20.00
), RegionNation AS (
    SELECT r.r_name, n.n_name, 
           CONCAT('Region: ', r.r_name, ' - Nation: ', n.n_name) AS region_nation
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
), CustomerOrders AS (
    SELECT c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           CONCAT(c.c_name, ' placed order ', o.o_orderkey, ' on ', CAST(o.o_orderdate AS VARCHAR), 
                  ' totaling ', CAST(o.o_totalprice AS VARCHAR)) AS customer_order
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_totalprice > 1000.00
)
SELECT sp.s_name, sp.description, rn.region_nation, co.customer_order
FROM SupplierParts sp
JOIN RegionNation rn ON rn.n_name IN (SELECT n.n_name FROM nation n WHERE n.n_nationkey IN 
                                       (SELECT s.s_nationkey FROM supplier s WHERE s.s_name = sp.s_name))
JOIN CustomerOrders co ON co.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey IN 
                                              (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = 
                                               (SELECT s.s_suppkey FROM supplier s WHERE s.s_name = sp.s_name)));
