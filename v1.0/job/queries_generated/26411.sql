WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.actors,
        rm.keywords,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM CURRENT_DATE) ORDER BY rm.cast_count DESC) AS rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 10
)

SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.actors,
    fm.keywords
FROM 
    FilteredMovies fm
WHERE 
    fm.rank <= 10
ORDER BY 
    fm.cast_count DESC;
