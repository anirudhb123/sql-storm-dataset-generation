WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_title AS t
    JOIN 
        aka_name AS a ON a.id = t.id
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        t.title,
        ARRAY_AGG(DISTINCT c.role_id) AS roles,
        COUNT(DISTINCT mi.id) AS info_count,
        MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS director,
        MAX(CASE WHEN mi.info_type_id = 2 THEN mi.info END) AS producer
    FROM 
        title AS t
    LEFT JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_info AS mi ON mi.movie_id = t.id
    GROUP BY 
        t.title
)
SELECT 
    rm.aka_name,
    rm.movie_title,
    rm.production_year,
    md.director,
    md.producer,
    md.info_count
FROM 
    RankedMovies AS rm
LEFT JOIN 
    MovieDetails AS md ON rm.movie_title = md.title
WHERE 
    (md.info_count > 0 OR md.director IS NOT NULL)
    AND rm.title_rank <= 5
ORDER BY 
    rm.production_year DESC, md.info_count DESC;
