WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie')
),
MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        MAX(r.role) AS main_role
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    rt.title,
    rt.production_year,
    mc.actor_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN mc.actor_count > 5 THEN 'Ensemble Cast'
        WHEN mc.actor_count IS NULL THEN 'No Cast Info'
        ELSE 'Small Cast'
    END AS cast_classification
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieCast mc ON rt.title_id = mc.movie_id
LEFT JOIN 
    MovieKeywords mk ON rt.title_id = mk.movie_id
WHERE 
    rt.title_rank <= 10
ORDER BY 
    rt.production_year DESC, mc.actor_count DESC;
