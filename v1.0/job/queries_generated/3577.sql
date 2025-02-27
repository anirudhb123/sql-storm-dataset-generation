WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
),
ActorMovies AS (
    SELECT 
        c.person_id,
        ct.kind AS role,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        cast_info c
    JOIN 
        role_type ct ON c.role_id = ct.id
    JOIN 
        title t ON c.movie_id = t.id
    GROUP BY 
        c.person_id, ct.kind
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(m.title, 'Unknown Title') AS movie_title,
        m.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    GROUP BY 
        m.id
)
SELECT 
    ak.name AS actor_name,
    am.role,
    am.movie_count,
    am.movie_titles,
    md.movie_title,
    md.production_year,
    md.company_count,
    rt.title_rank
FROM 
    aka_name ak
JOIN 
    ActorMovies am ON ak.person_id = am.person_id
LEFT JOIN 
    MovieDetails md ON ARRAY[1, 2]::INTEGER[] @> ARRAY[md.movie_id]
JOIN 
    RankedTitles rt ON md.title_id = rt.title_id 
WHERE 
    md.production_year BETWEEN 1990 AND 2023 
    AND rt.title_rank <= 5
ORDER BY 
    am.movie_count DESC, 
    ak.name ASC;
