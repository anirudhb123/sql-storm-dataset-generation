WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
PersonMovieStats AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        COUNT(DISTINCT CASE WHEN c.role_id IS NOT NULL THEN c.movie_id END) AS acting_roles
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name n ON c.person_id = n.person_id
    WHERE 
        c.person_role_id IS NOT NULL
    GROUP BY 
        c.person_id
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ' ORDER BY k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
MoviesWithCompanies AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(c.name, '; ') AS companies
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        m.id
),
FullMovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(p.total_movies, 0) AS total_movies,
        COALESCE(p.acting_roles, 0) AS acting_roles,
        k.keywords,
        c.companies
    FROM 
        RankedTitles t
    LEFT JOIN 
        PersonMovieStats p ON t.title_id = p.person_id
    LEFT JOIN 
        MoviesWithKeywords k ON t.title_id = k.movie_id
    LEFT JOIN 
        MoviesWithCompanies c ON t.title_id = c.movie_id
)
SELECT 
    *,
    CASE 
        WHEN total_movies > 5 THEN 'Prolific'
        WHEN acting_roles > 3 THEN 'Experienced Actor'
        ELSE 'Novice'
    END AS experience_level
FROM 
    FullMovieDetails
WHERE 
    (production_year >= 2000 AND production_year <= 2023)
    OR (keywords IS NOT NULL AND keywords ILIKE '%action%')
ORDER BY 
    production_year DESC, title;
