
WITH RankedMovies AS (
    SELECT 
        at.title,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS not_null_note_ratio,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON ci.movie_id = at.movie_id
    GROUP BY 
        at.title, at.production_year
),
ActorsByMovie AS (
    SELECT 
        at.title,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.title ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title at
    INNER JOIN 
        cast_info ci ON ci.movie_id = at.movie_id
    INNER JOIN 
        aka_name ak ON ak.person_id = ci.person_id
),
CompanyStats AS (
    SELECT 
        at.title,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(cn.name, ', ' ORDER BY cn.name) AS company_names
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = at.movie_id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    GROUP BY 
        at.title
)
SELECT 
    rm.title,
    rm.actor_count,
    rm.not_null_note_ratio,
    cb.company_count,
    cb.company_names,
    STRING_AGG(abm.actor_name, ', ' ORDER BY abm.actor_rank) AS actor_names
FROM 
    RankedMovies rm
JOIN 
    CompanyStats cb ON cb.title = rm.title
LEFT JOIN 
    ActorsByMovie abm ON abm.title = rm.title
WHERE 
    rm.rank <= 5
GROUP BY 
    rm.title, rm.actor_count, rm.not_null_note_ratio, cb.company_count, cb.company_names
ORDER BY 
    rm.actor_count DESC, rm.title;
