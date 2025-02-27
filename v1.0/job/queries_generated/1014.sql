WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    GROUP BY 
        a.person_id
),
MoviesWithInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        GROUP_CONCAT(DISTINCT mk.keyword) AS keywords,
        MAX(mi.info) AS info_notes
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id
)
SELECT 
    a.person_id,
    a.movie_count,
    a.movies,
    t.title,
    t.production_year,
    COALESCE(k.keywords, 'No Keywords') AS keywords,
    COALESCE(info_notes, 'No Additional Info') AS info_notes
FROM 
    ActorMovies a
JOIN 
    RankedTitles t ON a.movie_count > 1
LEFT JOIN 
    MoviesWithInfo k ON t.title = k.title
WHERE 
    t.title_rank <= 5
ORDER BY 
    a.movie_count DESC, 
    t.production_year DESC;
