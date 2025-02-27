WITH RankedMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),

MovieGenres AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),

CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name
)

SELECT 
    r.actor_name,
    r.movie_title,
    r.production_year,
    COALESCE(g.genres, 'Unknown') AS genres,
    COALESCE(ci.company_name, 'No Company') AS company_name,
    COALESCE(ci.company_types, 'No Types') AS company_types
FROM 
    RankedMovies r
LEFT JOIN 
    MovieGenres g ON r.movie_title = g.movie_title
LEFT JOIN 
    CompanyMovieInfo ci ON r.movie_title = ci.movie_title
WHERE 
    r.rn = 1
ORDER BY 
    r.production_year DESC,
    r.actor_name ASC;
