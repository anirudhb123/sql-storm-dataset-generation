WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.id AS movie_id,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        aka_title a
    LEFT JOIN
        cast_info c ON a.movie_id = c.movie_id
    LEFT JOIN
        movie_keyword mk ON a.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        aka_name ak ON a.movie_id = ak.person_id
    GROUP BY
        a.title, a.production_year, a.id
),
PopularMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        aka_names,
        keywords,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    pm.title,
    pm.production_year,
    pm.cast_count,
    pm.aka_names,
    pm.keywords
FROM 
    PopularMovies pm
WHERE 
    pm.rank <= 10
ORDER BY 
    pm.cast_count DESC;