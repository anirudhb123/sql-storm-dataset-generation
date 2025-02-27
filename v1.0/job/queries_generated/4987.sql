WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
),
ActorInfo AS (
    SELECT 
        a.name AS actor_name, 
        c.movie_id,
        COUNT(DISTINCT c.role_id) AS distinct_roles,
        MAX(c.nr_order) AS max_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        a.name, c.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    ai.actor_name,
    ai.distinct_roles,
    iw.info AS movie_info,
    COALESCE(mkw.keywords, 'No Keywords') AS keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    complete_cast cc ON rt.title_id = cc.movie_id
LEFT JOIN 
    ActorInfo ai ON cc.movie_id = ai.movie_id
LEFT JOIN 
    movie_info iw ON rt.title_id = iw.movie_id AND iw.info_type_id = 1
LEFT JOIN 
    MoviesWithKeywords mkw ON rt.title_id = mkw.movie_id
WHERE 
    rt.production_year > 2000
    AND (ai.distinct_roles IS NULL OR ai.distinct_roles > 1)
ORDER BY 
    rt.production_year DESC, 
    rt.title;
