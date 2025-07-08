WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_kind,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        pi.info AS actor_info
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type c ON mc.company_type_id = c.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN aka_name a ON cc.subject_id = a.person_id
    JOIN person_info pi ON a.person_id = pi.person_id
    WHERE t.production_year >= 2000 
      AND pi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Biography%')
),
AggregateResults AS (
    SELECT 
        movie_id,
        movie_title,
        COUNT(DISTINCT actor_name) AS actor_count,
        ARRAY_AGG(DISTINCT movie_keyword) AS keywords,
        MAX(production_year) AS latest_year
    FROM MovieDetails
    GROUP BY movie_id, movie_title
)
SELECT 
    ar.movie_id,
    ar.movie_title,
    ar.actor_count,
    ar.keywords,
    ar.latest_year
FROM AggregateResults ar
ORDER BY ar.latest_year DESC, ar.actor_count DESC;
