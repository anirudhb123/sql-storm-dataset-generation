WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        a.imdb_index AS actor_imdb_index,
        pi.info AS actor_info
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN aka_name a ON cc.subject_id = a.person_id
    LEFT JOIN person_info pi ON a.person_id = pi.person_id AND pi.info_type_id = 1
    WHERE 
        t.production_year >= 2000 AND 
        k.keyword LIKE 'Action%'
),
AggregatedResults AS (
    SELECT 
        movie_title,
        production_year,
        company_type,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT CONCAT(actor_name, ' (', actor_imdb_index, ')'), ', ') AS actors,
        STRING_AGG(DISTINCT actor_info, ', ') AS actor_infos
    FROM MovieDetails
    GROUP BY movie_title, production_year, company_type
)
SELECT 
    movie_title,
    production_year,
    company_type,
    keywords,
    actors,
    actor_infos
FROM AggregatedResults
ORDER BY production_year DESC, movie_title;
