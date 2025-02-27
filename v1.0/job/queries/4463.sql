WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        SUM(CASE WHEN ci.nr_order = 1 THEN 1 ELSE 0 END) AS main_cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
), 
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON an.person_id = ci.person_id
    GROUP BY 
        ci.movie_id
),
KeywordInfo AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.movie_id, 
    md.title, 
    md.production_year, 
    COALESCE(ac.actor_count, 0) AS actor_count,
    md.total_actors,
    md.main_cast_count,
    ki.keywords
FROM 
    MovieDetails md
LEFT JOIN 
    ActorCounts ac ON ac.movie_id = md.movie_id
LEFT JOIN 
    KeywordInfo ki ON ki.movie_id = md.movie_id
WHERE 
    md.total_actors > 5 
    AND (md.production_year > 2000 OR md.production_year IS NULL)
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
