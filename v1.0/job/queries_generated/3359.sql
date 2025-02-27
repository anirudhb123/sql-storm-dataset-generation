WITH RankedTitles AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopCast AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY ak.name) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        c.person_role_id IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rt.movie_title,
    rt.production_year,
    COALESCE(tc.actor_name, 'No Actors') AS leading_actor,
    COALESCE(mk.keywords, 'No Keywords') AS movie_keywords,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = rt.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')) AS rating_count
FROM 
    RankedTitles rt
LEFT JOIN 
    TopCast tc ON rt.id = tc.movie_id AND tc.actor_rank = 1
LEFT JOIN 
    MoviesWithKeywords mk ON rt.id = mk.movie_id
WHERE 
    rt.year_rank <= 5
ORDER BY 
    rt.production_year DESC, 
    rt.movie_title ASC;
