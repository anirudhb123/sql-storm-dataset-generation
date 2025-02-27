WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id
), FilteredMovies AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rn
    FROM 
        MovieDetails md
    WHERE 
        actor_count > 5
), TopMovies AS (
    SELECT 
        *,
        CASE 
            WHEN actor_count > 10 THEN 'Ensemble Cast'
            WHEN actor_count > 5 THEN 'Moderate Cast'
            ELSE 'Small Cast'
        END AS cast_size
    FROM 
        FilteredMovies
    WHERE 
        rn <= 3
), RelevantDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.cast_size,
        string_agg(DISTINCT mk.keyword, ', ') AS keyword_list,
        string_agg(DISTINCT ak.name, ', ') AS alternative_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        aka_name ak ON ak.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = tm.movie_id)
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = tm.movie_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, tm.cast_size
)
SELECT 
    rd.*,
    COALESCE(NULLIF(rd.keyword_list, ''), 'No keywords') AS keywords_display
FROM 
    RelevantDetails rd
ORDER BY 
    rd.production_year DESC, rd.cast_size DESC;
