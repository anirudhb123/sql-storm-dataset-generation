SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.md5sum IN ('0d0c7174f9dc5e5c622fd5795c36cc80', '320d29ada185659e3f03d6c16c72385e', '834aaaa80c376166514dd0c7b003ed61', '855f08ec3a45b05656d0d4ca5dae48e9', '92619966de18a41c4fb426b120bf91ba', 'c3ec42b84c76ce3a5ebed442a19cf581', 'eba2f3bb03596129b7705216131b6e86', 'ef160b6f83f265be0f7eedcb2b287fc1');