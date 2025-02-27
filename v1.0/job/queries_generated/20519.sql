WITH
    RankedMovies AS (
        SELECT 
            t.id AS movie_id,
            t.title,
            t.production_year,
            ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.title) AS title_rank
        FROM 
            aka_title t
    ),
    CastDetails AS (
        SELECT 
            ci.movie_id,
            COUNT(DISTINCT ci.person_id) AS cast_count,
            STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
        FROM 
            cast_info ci
        JOIN 
            aka_name ak ON ci.person_id = ak.person_id
        WHERE 
            ak.name IS NOT NULL
        GROUP BY 
            ci.movie_id
    ),
    MovieGenre AS (
        SELECT 
            m.id AS movie_id,
            k.keyword AS genre
        FROM 
            aka_title m
        JOIN 
            movie_keyword mk ON m.id = mk.movie_id
        JOIN 
            keyword k ON mk.keyword_id = k.id
    ),
    GenreCount AS (
        SELECT 
            movie_id,
            COUNT(DISTINCT genre) AS genre_count
        FROM 
            MovieGenre
        GROUP BY 
            movie_id
    )
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(cd.cast_count, 0) AS cast_count,
    COALESCE(cd.actor_names, 'None') AS actor_names,
    COALESCE(gc.genre_count, 0) AS genre_count,
    (CASE WHEN gc.genre_count > 0 THEN 'Has Genres' ELSE 'No Genres' END) AS genre_status,
    CASE 
        WHEN r.production_year IS NOT NULL AND r.title_rank = 1 THEN 'Top Film of the Year'
        ELSE 'Regular Film'
    END AS film_status,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = r.movie_id) AS info_count
FROM 
    RankedMovies r
LEFT JOIN 
    CastDetails cd ON r.movie_id = cd.movie_id
LEFT JOIN 
    GenreCount gc ON r.movie_id = gc.movie_id
WHERE 
    r.production_year > 2000
ORDER BY 
    r.production_year DESC,
    r.title;
