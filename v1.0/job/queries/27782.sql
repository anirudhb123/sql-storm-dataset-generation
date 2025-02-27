WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name AS ak ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_keyword AS mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword AS k ON k.id = mk.keyword_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id, title, production_year, cast_count, aka_names, keywords,
        RANK() OVER (ORDER BY cast_count DESC) AS rank_by_cast_count
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.aka_names,
    fm.keywords
FROM 
    FilteredMovies AS fm
WHERE 
    fm.rank_by_cast_count <= 10
ORDER BY 
    fm.rank_by_cast_count;
