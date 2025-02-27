WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY b.nr_order DESC) AS rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info b ON a.id = b.movie_id
    LEFT JOIN 
        aka_name c ON b.person_id = c.person_id
    WHERE 
        a.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.rank,
        COALESCE(d.info, 'No Info Available') AS info,
        rm.cast_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info d ON rm.movie_id = d.movie_id AND d.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.rank,
    md.info,
    CASE 
        WHEN md.cast_count > 10 THEN 'Large Cast'
        WHEN md.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    md.rank <= 5
GROUP BY 
    md.movie_id, md.title, md.production_year, md.rank, md.info, md.cast_count
ORDER BY 
    md.production_year DESC, md.rank;
