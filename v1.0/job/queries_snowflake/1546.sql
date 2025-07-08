
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(CASE WHEN c.role_id IS NOT NULL THEN 1 END) AS cast_count,
        LISTAGG(CASE WHEN ak.name IS NOT NULL THEN ak.name ELSE 'Unknown' END, ', ') AS actor_names,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count,
        actor_names,
        keyword_count,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.actor_names, 'No Cast') AS actor_names,
    tm.cast_count,
    COALESCE(bt.info, 'No additional info') AS additional_info
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    (SELECT movie_id, info FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'box office')) bt ON tm.movie_id = bt.movie_id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.cast_count DESC, 
    tm.production_year DESC;
