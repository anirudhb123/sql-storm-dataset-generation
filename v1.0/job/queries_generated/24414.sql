WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_title,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),

CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

MoviesWithDetails AS (
    SELECT 
        t.title,
        t.production_year,
        cd.actor_name,
        cd.role_name,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        rt.rank_title,
        rt.total_titles
    FROM 
        RankedTitles rt
    LEFT JOIN 
        CastDetails cd ON rt.title_id = cd.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rt.title_id = mk.movie_id
)

SELECT 
    movie.title,
    movie.production_year,
    movie.actor_name,
    movie.role_name,
    movie.keywords,
    CASE 
        WHEN movie.actor_rank = 1 THEN 'Lead' 
        ELSE 'Supporting' 
    END AS role_category,
    CASE 
        WHEN movie.total_titles > 5 THEN 'Popular Year' 
        ELSE 'Less Popular Year' 
    END AS popularity_status
FROM 
    MoviesWithDetails movie
WHERE 
    movie.production_year BETWEEN 2000 AND 2023
    AND (movie.keywords LIKE '%Action%' OR movie.keywords LIKE '%Drama%')
ORDER BY 
    movie.production_year DESC, movie.title
LIMIT 50;
