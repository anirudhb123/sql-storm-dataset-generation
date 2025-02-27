WITH RECURSIVE ActorMovies AS (
    SELECT c.person_id, c.movie_id, 1 AS level
    FROM cast_info c
    INNER JOIN aka_name a ON c.person_id = a.person_id
    WHERE a.name LIKE 'Tom%'

    UNION ALL

    SELECT c.person_id, c.movie_id, am.level + 1
    FROM cast_info c
    INNER JOIN ActorMovies am ON c.movie_id = am.movie_id
    INNER JOIN aka_name a ON c.person_id = a.person_id
    WHERE a.name NOT LIKE 'Tom%'
),
TopMovies AS (
    SELECT m.id AS movie_id, m.title, COUNT(DISTINCT c.person_id) AS cast_count
    FROM title m
    JOIN cast_info c ON m.id = c.movie_id
    GROUP BY m.id
    HAVING COUNT(DISTINCT c.person_id) > 5
),
MovieKeywords AS (
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
MovieDetails AS (
    SELECT t.id AS movie_id, t.title, t.production_year, tk.keywords, 
           COALESCE(mci.note, 'No Production Company') AS production_company
    FROM title t
    LEFT JOIN MovieKeywords tk ON t.id = tk.movie_id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = 1
    LEFT JOIN movie_info_idx mci ON mci.movie_id = t.id
    WHERE t.production_year >= 2000
)
SELECT md.movie_id, md.title, md.production_year, md.keywords, 
       COUNT(DISTINCT ac.person_id) AS total_actors,
       ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.movie_id) AS rn
FROM MovieDetails md
LEFT JOIN ActorMovies ac ON md.movie_id = ac.movie_id
GROUP BY md.movie_id, md.title, md.production_year, md.keywords
ORDER BY md.production_year DESC, total_actors DESC;
