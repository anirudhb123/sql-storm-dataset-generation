WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        k.keyword AS movie_keyword,
        ak.name AS actor_name
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type c ON mc.company_type_id = c.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN aka_name ak ON cc.subject_id = ak.person_id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year > 2000
),
AggregatedData AS (
    SELECT
        movie_title,
        production_year,
        COUNT(DISTINCT actor_name) AS total_actors,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM MovieDetails
    GROUP BY movie_title, production_year
)
SELECT 
    movie_title,
    production_year,
    total_actors,
    keywords
FROM AggregatedData
WHERE total_actors > 5
ORDER BY production_year DESC, total_actors DESC;
