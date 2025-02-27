WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank_year
    FROM 
        aka_title a
    WHERE 
        a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
), 
cast_summary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        c.movie_id
), 
movie_info_filtered AS (
    SELECT 
        m.movie_id,
        MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis') THEN mi.info END) AS synopsis,
        MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards') THEN mi.info END) AS awards_info
    FROM 
        movie_info m
    JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.rank_year,
    COALESCE(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.cast_names, 'No cast available') AS cast_names,
    COALESCE(mif.synopsis, 'No synopsis available') AS synopsis,
    COALESCE(mif.awards_info, 'No awards information') AS awards_info
FROM 
    ranked_movies r
LEFT JOIN 
    cast_summary cs ON r.movie_id = cs.movie_id
LEFT JOIN 
    movie_info_filtered mif ON r.movie_id = mif.movie_id
WHERE 
    r.production_year >= 2000
    AND (mif.awards_info IS NULL OR mif.awards_info != '')
ORDER BY 
    r.production_year DESC, 
    r.rank_year;
