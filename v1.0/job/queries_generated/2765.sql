WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COUNT(DISTINCT m.movie_id) OVER (PARTITION BY a.production_year) AS movie_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword m ON a.id = m.movie_id
    LEFT JOIN 
        keyword k ON m.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL
), CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS cast_count,
        AVG(CASE WHEN pi.info IS NOT NULL THEN 1 ELSE 0 END) AS has_info_ratio
    FROM 
        cast_info c
    LEFT JOIN 
        person_info pi ON c.person_id = pi.person_id
    GROUP BY 
        c.movie_id
), PopularMovies AS (
    SELECT 
        r.title,
        r.production_year,
        c.cast_count,
        r.keyword,
        COALESCE(cast_count, 0) AS cast_count,
        r.movie_count
    FROM 
        RankedMovies r
    LEFT JOIN 
        CastDetails c ON r.title = (SELECT title FROM aka_title WHERE id = r.id)
    WHERE 
        r.year_rank <= 3
    ORDER BY 
        r.production_year DESC, r.movie_count DESC
)
SELECT 
    title,
    production_year,
    keyword,
    cast_count,
    movie_count
FROM 
    PopularMovies
WHERE 
    movie_count > 1
  AND 
    keyword IS NOT NULL
  AND 
    CAST(cast_count AS FLOAT) / NULLIF(movie_count, 0) > 0.5
ORDER BY 
    production_year DESC, title;
