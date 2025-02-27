WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS entire_cast,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        kind_id,
        cast_count,
        entire_cast,
        keywords,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000
        AND kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%')
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_count,
    f.entire_cast,
    f.keywords
FROM 
    FilteredMovies f
WHERE 
    f.rank <= 10
ORDER BY 
    f.cast_count DESC;
