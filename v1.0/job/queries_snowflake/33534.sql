
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        aka_title t
    INNER JOIN 
        MovieHierarchy mh 
    ON 
        t.episode_of_id = mh.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names
    FROM 
        MovieHierarchy m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.movie_id, m.title, m.production_year
),
MovieKeyword AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mi.movie_id,
    mi.title,
    mi.production_year,
    mi.cast_count,
    mi.cast_names,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY mi.production_year ORDER BY mi.cast_count DESC) AS rank
FROM 
    MovieInfo mi
LEFT JOIN 
    MovieKeyword mk ON mi.movie_id = mk.movie_id
ORDER BY 
    mi.production_year DESC, rank
LIMIT 10;
