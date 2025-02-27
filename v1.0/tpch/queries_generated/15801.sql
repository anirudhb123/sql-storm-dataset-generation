SELECT p.partkey, p.name, s.name AS supplier_name, ps.availqty 
FROM part p 
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey 
ORDER BY p.partkey LIMIT 100;
