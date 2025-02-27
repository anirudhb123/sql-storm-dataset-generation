WITH MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN company_type c ON mc.company_type_id = c.id
    LEFT JOIN complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    WHERE m.production_year >= 2000
    GROUP BY m.id
),
ActorInfo AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT m.title, ', ') AS movies
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN title m ON ci.movie_id = m.id
    GROUP BY a.person_id, a.name
)
SELECT 
    mi.movie_id,
    mi.movie_title,
    mi.production_year,
    mi.keywords,
    mi.company_types,
    mi.actor_count,
    ai.name AS actor_name,
    ai.movie_count,
    ai.movies
FROM MovieInfo mi
LEFT JOIN ActorInfo ai ON ai.movie_count > 0
ORDER BY mi.production_year DESC, mi.movie_title;
