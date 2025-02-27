WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ac.actor_count,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        COALESCE(ci.kind, 'Unknown') AS company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.movie_id = ac.movie_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_type ci ON mc.company_type_id = ci.id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    md.keyword,
    CASE 
        WHEN md.production_year < 2000 THEN 'Classic'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_age_category,
    CONCAT('Title: ', md.title, ' - Year: ', md.production_year) AS detailed_info
FROM 
    MovieDetails md
WHERE 
    md.actor_count IS NOT NULL 
    AND md.actor_count > (
        SELECT AVG(actor_count) 
        FROM ActorCounts
    )
ORDER BY 
    md.production_year DESC, 
    md.title ASC
LIMIT 20;
