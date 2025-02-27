
WITH MovieRoleCounts AS (
    SELECT m.id AS movie_id, COUNT(DISTINCT c.person_id) AS actor_count
    FROM aka_title m
    JOIN cast_info c ON m.id = c.movie_id
    GROUP BY m.id
),
TopMovies AS (
    SELECT movie_id, actor_count
    FROM MovieRoleCounts
    WHERE actor_count > 10
),
MovieDetails AS (
    SELECT m.id AS movie_id, m.title, m.production_year, a.name AS actor_name, ct.kind AS company_type
    FROM aka_title m
    LEFT JOIN cast_info c ON m.id = c.movie_id
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE m.production_year >= 2000
),
GenreKeywords AS (
    SELECT m.id AS movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM aka_title m
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.id
),
CombinedResults AS (
    SELECT md.title, md.production_year, md.actor_name, md.company_type, gk.keywords
    FROM MovieDetails md
    LEFT JOIN GenreKeywords gk ON md.movie_id = gk.movie_id
)
SELECT title, production_year, 
       actor_name, 
       COALESCE(company_type, 'Unknown') AS company_type,
       CASE 
           WHEN keywords IS NULL THEN 'No Keywords'
           ELSE keywords 
       END AS keywords
FROM CombinedResults
WHERE title IS NOT NULL
ORDER BY production_year DESC, actor_name ASC
LIMIT 50;
