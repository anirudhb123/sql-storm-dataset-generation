WITH RankedTitles AS (
    SELECT 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS actor_count, 
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
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
    COALESCE(cd.actor_count, 0) AS total_actors,
    COALESCE(cd.actor_names, 'No actors') AS actors_list,
    COALESCE(mk.keywords, 'No keywords') AS keywords_list,
    CASE 
        WHEN rt.title_rank = 1 THEN 'Best Title'
        ELSE 'Regular Title' 
    END AS title_category
FROM 
    RankedTitles rt
LEFT JOIN 
    CastDetails cd ON rt.title = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON rt.title = mk.movie_id
WHERE 
    rt.production_year >= 2000 AND
    rt.production_year < 2025
ORDER BY 
    rt.production_year DESC, 
    rt.title;
