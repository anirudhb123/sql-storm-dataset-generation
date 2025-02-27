WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
), 
MovieDetails AS (
    SELECT 
        m.title,
        COALESCE(mt.info, 'No info available') AS movie_info,
        a.name AS actor_name,
        a.id AS actor_id,
        t.production_year,
        rt.rank
    FROM 
        RankedTitles rt
    JOIN 
        title m ON rt.title = m.title
    LEFT JOIN 
        movie_info mt ON m.id = mt.movie_id AND mt.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        rt.rank <= 5
), 
FilteredMovies AS (
    SELECT 
        *,
        COUNT(*) OVER (PARTITION BY production_year) AS actor_count
    FROM 
        MovieDetails
    WHERE 
        actor_name IS NOT NULL
)

SELECT 
    f.title,
    f.production_year,
    f.movie_info,
    COALESCE(f.actor_name, 'Unknown Actor') AS actor_name,
    f.actor_count,
    CASE 
        WHEN f.actor_count > 10 THEN 'Many Actors'
        WHEN f.actor_count BETWEEN 5 AND 10 THEN 'Moderate Actors'
        ELSE 'Few Actors'
    END AS actor_density
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, f.actor_count DESC;
