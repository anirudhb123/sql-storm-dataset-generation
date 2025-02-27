WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieGenres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS genres
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT c.name || ' (' || ct.kind || ')', ', ') AS companies
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id
),
MoviesWithExtras AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        COALESCE(mg.genres, 'No Genre') AS genres,
        COALESCE(cd.companies, 'No Companies') AS companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieGenres mg ON rm.movie_id = mg.movie_id
    LEFT JOIN 
        CompanyDetails cd ON rm.movie_id = cd.movie_id
)
SELECT 
    m.title,
    m.production_year,
    m.actor_count,
    m.genres,
    m.companies,
    CASE 
        WHEN m.actor_count > 10 THEN 'Star-Studded'
        WHEN m.actor_count BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Less Popular'
    END AS popularity_label
FROM 
    MoviesWithExtras m
WHERE 
    m.production_year >= 2000
    AND (m.actor_count IS NOT NULL OR m.genres IS NOT NULL)
    AND NOT EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = m.movie_id 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
        AND mi.info IS NULL
    )
ORDER BY 
    m.production_year DESC, m.actor_count DESC;

