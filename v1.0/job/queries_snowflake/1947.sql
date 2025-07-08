
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorsInMovies AS (
    SELECT 
        ca.movie_id,
        COUNT(DISTINCT ca.person_id) AS actor_count
    FROM 
        cast_info ca
    WHERE 
        ca.role_id IN (SELECT id FROM role_type WHERE role LIKE '%lead%')
    GROUP BY 
        ca.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ak.actor_count, 0) AS lead_actor_count,
    COALESCE(mk.keywords, 'No keywords') AS related_keywords,
    CASE 
        WHEN rm.year_rank = 1 THEN 'Best Movie of the Year'
        ELSE NULL
    END AS ranking_note
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorsInMovies ak ON rm.movie_id = ak.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.production_year >= 2000
GROUP BY 
    rm.title, rm.production_year, ak.actor_count, mk.keywords, rm.year_rank
ORDER BY 
    rm.production_year DESC, rm.title;
