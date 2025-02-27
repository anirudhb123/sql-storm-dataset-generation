WITH MovieStats AS (
    SELECT t.title AS movie_title,
           t.production_year,
           COUNT(DISTINCT c.person_id) AS total_cast,
           STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
           STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM title t
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name co ON co.id = mc.company_id
    LEFT JOIN complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN cast_info c ON c.movie_id = t.id
    LEFT JOIN aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword kw ON kw.id = mk.keyword_id
    WHERE t.production_year >= 2000
      AND co.country_code = 'USA'
    GROUP BY t.id
),
OverallStats AS (
    SELECT AVG(total_cast) AS avg_cast_per_movie,
           COUNT(*) AS total_movies,
           STRING_AGG(DISTINCT movie_title, '; ') AS movies_list
    FROM MovieStats
)
SELECT os.avg_cast_per_movie,
       os.total_movies,
       os.movies_list
FROM OverallStats os;
