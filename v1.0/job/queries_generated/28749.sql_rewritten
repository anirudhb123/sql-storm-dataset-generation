WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        aka_name.name AS actor_name,
        row_number() OVER (PARTITION BY title.id ORDER BY cast_info.nr_order) AS actor_rank
    FROM 
        title
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        title.production_year BETWEEN 2000 AND 2020 
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        STRING_AGG(actor_name, ', ') AS actors
    FROM 
        RankedMovies
    WHERE 
        actor_rank <= 3 
    GROUP BY 
        movie_id, title, production_year
),
KeywordCount AS (
    SELECT 
        movie_id,
        COUNT(keyword.id) AS keyword_count
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_id
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.actors,
    kc.keyword_count
FROM 
    FilteredMovies fm
LEFT JOIN 
    KeywordCount kc ON fm.movie_id = kc.movie_id
ORDER BY 
    fm.production_year DESC, fm.title;