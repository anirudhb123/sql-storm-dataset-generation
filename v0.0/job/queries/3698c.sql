SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.episode_of_id < 660303 AND cn.name_pcode_nf > 'M4536' AND k.keyword IN ('battle-plan', 'dog-bone', 'empress-alexandra-fyodorovna', 'equity-waiver-theatre', 'glass-sword', 'harsh-judging', 'latin-quotation', 'reference-to-surya-bonaly', 'spiral-arm', 'teeth-break-like-glass') AND mc.note < '(1997) (Cuba) (TV)';