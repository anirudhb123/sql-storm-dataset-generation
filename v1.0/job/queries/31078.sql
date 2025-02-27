
WITH RECURSIVE MovieCte AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        mc.movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mc.level + 1
    FROM 
        MovieCte mc
    JOIN 
        movie_link ml ON mc.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mc.level < 3
),
RankedMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY m.kind_id) AS total_per_kind
    FROM 
        MovieCte m
)

SELECT 
    mv.title,
    mv.production_year,
    ct.kind,
    ak.name AS actor_name,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    CASE 
        WHEN mv.production_year IS NULL THEN 'Year Unknown'
        ELSE CAST(mv.production_year AS VARCHAR)
    END AS production_year_display
FROM 
    RankedMovies mv
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mv.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mv.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mv.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    kind_type ct ON ct.id = mv.kind_id
WHERE 
    mv.title_rank <= 5 AND 
    mv.total_per_kind > 10
GROUP BY 
    mv.movie_id, mv.title, mv.production_year, ct.kind, ak.name
HAVING 
    COUNT(DISTINCT k.id) > 2
ORDER BY 
    mv.production_year DESC, mv.title;
