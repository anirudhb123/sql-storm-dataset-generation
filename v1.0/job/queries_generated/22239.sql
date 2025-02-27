WITH MovieData AS (
    SELECT 
        t.id AS title_id,
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_order,
        COUNT(c.id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info mi ON mi.movie_id = t.movie_id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Duration') -- Ensure a specific info type
),
FilteredMovies AS (
    SELECT 
        md.title_id, 
        md.title, 
        md.production_year,
        md.year_order,
        md.cast_count
    FROM 
        MovieData md
    WHERE 
        md.cast_count > 0  -- Only include movies with a cast
        AND md.year_order <= 5 -- Limit to first 5 movies per year
),
ActorData AS (
    SELECT 
        ak.name AS actor_name,
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS unique_actors
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    GROUP BY 
        ak.name, c.movie_id
),
MovieSummary AS (
    SELECT 
        fm.title, 
        fm.production_year, 
        COALESCE(ad.unique_actors, 0) AS unique_actors,
        fm.cast_count,
        CASE 
            WHEN fm.production_year < 2000 THEN 'Classic'
            WHEN fm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        ActorData ad ON fm.title_id = ad.movie_id
)
SELECT 
    ms.production_year,
    ms.era,
    COUNT(ms.title) AS movie_count,
    SUM(ms.unique_actors) AS total_unique_actors,
    AVG(ms.cast_count * 1.0) AS avg_cast_count,
    STRING_AGG(DISTINCT ms.title, ', ') AS movie_titles,
    MAX(CASE WHEN ms.production_year = (SELECT MAX(production_year) FROM FilteredMovies) 
             THEN ms.unique_actors ELSE NULL END) AS peak_actors
FROM 
    MovieSummary ms
GROUP BY 
    ms.production_year, ms.era
HAVING 
    COUNT(ms.title) > 1  -- Only include years with more than one movie
ORDER BY 
    ms.production_year DESC NULLS LAST;
