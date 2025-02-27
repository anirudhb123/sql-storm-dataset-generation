WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword,
        rm.cast_count,
        ROW_NUMBER() OVER (PARTITION BY rm.keyword ORDER BY rm.cast_count DESC) AS rank
    FROM 
        RankedMovies rm
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.keyword,
    fm.cast_count
FROM 
    FilteredMovies fm
WHERE 
    fm.rank <= 3
ORDER BY 
    fm.keyword,
    fm.cast_count DESC;
