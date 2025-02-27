SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.md5sum IN ('38b8efa1a0de25222031784ec902d659', '3dcfd785b7157a3be6852ee14ee21206', '3e9ea3a1a6da8b1ad456110682068988', '4a104c0a1099d86b3ec8abed4386af76', '79c83717ccb73803f9db6209f444c945', '910dd2abe9340a35069990a650dda182');