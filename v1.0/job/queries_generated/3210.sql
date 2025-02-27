WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(distinct c.person_id) DESC) AS actor_count_rank
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id
),
ActorInfo AS (
    SELECT 
        a.person_id,
        a.name,
        COALESCE(pi.info, 'No Info') AS personal_info,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        person_info pi ON a.person_id = pi.person_id
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name, pi.info
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    ai.name AS actor_name,
    ai.personal_info,
    ai.movie_count,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = rt.title_id AND mi.info_type_id = 1) AS additional_info_count,
    (SELECT STRING_AGG(DISTINCT k.keyword, ', ') FROM movie_keyword mk JOIN keyword k ON mk.keyword_id = k.id WHERE mk.movie_id = rt.title_id) AS keywords
FROM 
    RankedTitles rt
JOIN 
    ActorInfo ai ON rt.actor_count_rank <= 5
WHERE 
    rt.production_year IS NOT NULL
ORDER BY 
    rt.production_year DESC, 
    rt.title;
