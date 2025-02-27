WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.id) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(CONCAT_WS(' ', n.name, n.surname_pcode), ', ') AS cast_names
    FROM 
        cast_info c
    LEFT JOIN 
        name n ON c.person_id = n.imdb_id
    GROUP BY 
        c.movie_id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        COALESCE(cast.cast_count, 0) AS total_cast,
        COALESCE(cast.cast_names, 'No Cast Available') AS cast_members
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        CastDetails cast ON m.id = cast.movie_id
),
ExternalLink AS (
    SELECT 
        ml.movie_id,
        COUNT(DISTINCT ml.linked_movie_id) AS linked_movie_count
    FROM 
        movie_link ml
    GROUP BY 
        ml.movie_id
)
SELECT 
    mi.title,
    mi.production_year,
    CASE 
        WHEN mi.total_cast > 10 THEN 'Large Cast'
        WHEN mi.total_cast > 0 THEN 'Small Cast'
        ELSE 'No Cast'
    END AS cast_size,
    el.linked_movie_count,
    (SELECT 
        AVG(cast_count)
     FROM 
        CastDetails) AS average_cast_count
FROM 
    MovieInfo mi
LEFT JOIN 
    ExternalLink el ON mi.movie_id = el.movie_id
WHERE 
    mi.keyword IS NOT NULL
    AND (mi.total_cast > 0 OR mi.total_cast IS NULL)
ORDER BY 
    mi.production_year DESC, 
    title_rank ASC
LIMIT 50 OFFSET 10;
