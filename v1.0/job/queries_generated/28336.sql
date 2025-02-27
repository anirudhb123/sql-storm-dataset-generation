WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY YEAR(t.production_year) ORDER BY t.production_year DESC) AS rank_by_year
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'series'))
),
SelectedActors AS (
    SELECT 
        a.name AS actor_name,
        r.role AS role_type,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL AND 
        a.name <> ''
),
DetailedMovieInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT a.actor_name || ' (' || a.role_type || ')', ', ') AS cast_details
    FROM 
        RankedMovies m
    LEFT JOIN 
        SelectedActors a ON m.movie_id = a.movie_id
    WHERE 
        m.rank_by_year <= 10  -- Top 10 movies per year
    GROUP BY 
        m.movie_id, m.title, m.production_year
)
SELECT 
    d.movie_id,
    d.title,
    d.production_year,
    d.cast_details,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM 
    DetailedMovieInfo d
LEFT JOIN 
    movie_keyword mk ON d.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    d.production_year >= 2000  -- Considering only movies from the year 2000 onwards
GROUP BY 
    d.movie_id, d.title, d.production_year, d.cast_details
ORDER BY 
    d.production_year DESC, d.title;
