WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        mt.kind_id,
        COUNT(DISTINCT ci.person_id) AS total_cast_members,
        DENSE_RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year, mt.kind_id
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),
FilteredMovies AS (
    SELECT 
        r.title,
        r.production_year,
        r.kind_id,
        r.total_cast_members
    FROM 
        RankedMovies r
    WHERE 
        r.year_rank <= 3
),
MovieDetails AS (
    SELECT 
        f.title,
        f.production_year,
        f.total_cast_members,
        ARRAY_AGG(DISTINCT c.name) AS cast_member_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        FilteredMovies f
    LEFT JOIN 
        cast_info ci ON f.title = (SELECT title FROM aka_title WHERE id = ci.movie_id LIMIT 1)
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = ci.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        f.title, f.production_year, f.total_cast_members
)
SELECT 
    m.title,
    m.production_year,
    m.total_cast_members,
    COALESCE(m.cast_member_names, ARRAY['No cast members']) AS cast_member_names,
    COALESCE(m.keywords, 'No keywords available') AS keywords,
    CASE 
        WHEN m.total_cast_members > 10 THEN 'Big Cast'
        WHEN m.total_cast_members BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    MovieDetails m
WHERE 
    m.production_year IS NOT NULL
    AND m.production_year > (SELECT AVG(production_year) FROM aka_title)
ORDER BY 
    m.total_cast_members DESC, 
    m.production_year ASC;

-- Ensuring that secondary rankings and results handle cases with NULL values gracefully
