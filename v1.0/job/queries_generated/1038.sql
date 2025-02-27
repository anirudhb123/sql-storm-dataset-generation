WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_title,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.rank_title,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count > 5
)
SELECT 
    DISTINCT f.movie_id,
    f.title,
    f.production_year,
    COALESCE(k.keyword, 'No Keyword') AS movie_keyword,
    COUNT(DISTINCT ci.person_id) OVER (PARTITION BY f.movie_id) AS unique_cast_members,
    TMDB.id AS tmdb_id,
    COALESCE(cn.name, 'Unknown Company') AS production_company
FROM 
    FilteredMovies f
LEFT JOIN 
    movie_keyword mk ON f.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON f.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    title TMDB ON f.movie_id = TMDB.imdb_id
WHERE 
    f.production_year >= 2000
ORDER BY 
    f.production_year DESC, f.rank_title;
