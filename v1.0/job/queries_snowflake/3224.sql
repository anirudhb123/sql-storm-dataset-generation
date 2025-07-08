
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
PopularActors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT mi.info, '; ') WITHIN GROUP (ORDER BY mi.info) AS info_details
    FROM 
        movie_info mi
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre')
    GROUP BY 
        mi.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    pa.name AS popular_actor,
    COALESCE(mv.info_details, 'No Genre Info') AS genre_info
FROM 
    RankedTitles rt
LEFT JOIN 
    cast_info ci ON ci.movie_id = rt.title_id
LEFT JOIN 
    PopularActors pa ON ci.person_id = pa.actor_id
LEFT JOIN 
    MovieInfo mv ON mv.movie_id = rt.title_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, rt.title ASC;
