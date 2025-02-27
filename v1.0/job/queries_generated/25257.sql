WITH MovieInfo AS (
    SELECT t.title, 
           t.production_year, 
           c.kind AS company_type, 
           a.name AS actor_name, 
           STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
           ARRAY_AGG(DISTINCT p.info) AS person_info,
           COUNT(DISTINCT c.person_id) AS actor_count
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type c ON mc.company_type_id = c.id
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN person_info p ON ci.person_id = p.person_id
    WHERE t.production_year >= 2000
      AND c.kind LIKE 'Production%'
    GROUP BY t.id, t.title, t.production_year, c.kind, a.name
),
RankedMovies AS (
    SELECT title, 
           production_year, 
           company_type, 
           actor_name, 
           keywords, 
           person_info, 
           actor_count,
           ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rank
    FROM MovieInfo
)
SELECT rank, 
       title, 
       production_year, 
       company_type, 
       actor_name, 
       keywords, 
       person_info
FROM RankedMovies
WHERE rank <= 5
ORDER BY production_year DESC, rank;
