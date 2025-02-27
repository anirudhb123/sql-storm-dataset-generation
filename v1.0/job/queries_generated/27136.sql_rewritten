WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
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
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM cast('2024-10-01' as date)) - rm.production_year ORDER BY rm.cast_count DESC) AS rank_by_age
    FROM 
        RankedMovies AS rm
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.actors,
    fm.keywords,
    fm.rank_by_age
FROM 
    FilteredMovies AS fm
WHERE 
    fm.rank_by_age <= 5
ORDER BY 
    fm.production_year DESC, fm.cast_count DESC;