WITH MovieDetails AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ct.kind AS company_type,
        ki.keyword AS movie_keyword,
        pi.info AS actor_info
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN title mt ON ci.movie_id = mt.id
    LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN person_info pi ON ak.person_id = pi.person_id
    WHERE mt.production_year >= 2000
      AND ak.name IS NOT NULL
      AND (pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'bio'))
),
AggregatedData AS (
    SELECT 
        movie_title, 
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        AVG(production_year) AS avg_production_year
    FROM MovieDetails
    GROUP BY movie_title
)
SELECT 
    movie_title,
    actors,
    keywords,
    avg_production_year
FROM AggregatedData
WHERE avg_production_year < 2010
ORDER BY avg_production_year DESC;
