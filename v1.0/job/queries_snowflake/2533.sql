
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorsWithMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        c.movie_id
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    WHERE 
        EXISTS (SELECT 1 FROM complete_cast cc WHERE cc.movie_id = c.movie_id)
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    ak.name AS actor_name,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = rt.title_id) AS info_count
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorsWithMovies ak ON ak.movie_id = rt.title_id
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = rt.title_id
WHERE 
    rt.rn <= 10
ORDER BY 
    rt.production_year DESC, 
    ak.name;
