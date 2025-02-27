WITH RecursiveMovieData AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank,
        (
            SELECT COUNT(*) 
            FROM movie_keyword mk 
            WHERE mk.movie_id = t.id
        ) AS total_keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_type,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
FilteredMovies AS (
    SELECT 
        rmd.movie_id,
        rmd.title,
        rmd.production_year,
        COUNT(cd.actor_name) AS actor_count,
        MAX(cd.actor_order) AS max_actor_order,
        SUM(CASE WHEN cd.role_type = 'Lead' THEN 1 ELSE 0 END) AS lead_actors
    FROM 
        RecursiveMovieData rmd
    LEFT JOIN 
        CastDetails cd ON rmd.movie_id = cd.movie_id
    GROUP BY 
        rmd.movie_id, rmd.title, rmd.production_year
    HAVING 
        COUNT(cd.actor_name) > 1 AND 
        lead_actors > 0
)
SELECT 
    fm.title,
    fm.production_year,
    fm.actor_count,
    fm.max_actor_order,
    fm.lead_actors,
    CASE 
        WHEN fm.max_actor_order > 5 THEN 'Many Actors'
        WHEN fm.max_actor_order BETWEEN 2 AND 5 THEN 'Moderate Actors'
        ELSE 'Few Actors'
    END AS actor_category,
    STRING_AGG(DISTINCT rmd.keyword, ', ') AS keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    RecursiveMovieData rmd ON fm.movie_id = rmd.movie_id
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, 
    fm.actor_count, fm.max_actor_order, fm.lead_actors
ORDER BY 
    fm.production_year DESC, fm.actor_count DESC;

