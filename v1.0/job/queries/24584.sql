WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),

MovieRoleInfo AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        MIN(ak.name) AS first_cast_member
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    JOIN 
        RankedMovies m ON m.movie_id = c.movie_id
    GROUP BY 
        m.movie_id
),

CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cmp.id) AS total_companies,
        STRING_AGG(DISTINCT cmp.name, ', ') AS companies,
        MAX(CASE WHEN ct.kind = 'Distributor' THEN cmp.name END) AS distributor_name
    FROM 
        movie_companies mc
    JOIN 
        company_name cmp ON cmp.id = mc.company_id
    JOIN 
        company_type ct ON ct.id = mc.company_type_id
    GROUP BY 
        mc.movie_id
),

FinalBenchmark AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mri.total_cast, 0) AS total_cast,
        COALESCE(mri.actor_names, 'N/A') AS actor_names,
        COALESCE(cmi.total_companies, 0) AS total_companies,
        COALESCE(cmi.companies, 'N/A') AS companies,
        COALESCE(cmi.distributor_name, 'N/A') AS distributor_name,
        rm.title_rank,
        rm.total_movies,
        CASE 
            WHEN rm.production_year < 2000 THEN 'Classic'
            WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era,
        CASE 
            WHEN mri.total_cast IS NULL THEN 'No Cast Information'
            ELSE 'Actors Available'
        END AS cast_info_status
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieRoleInfo mri ON mri.movie_id = rm.movie_id
    LEFT JOIN 
        CompanyMovieInfo cmi ON cmi.movie_id = rm.movie_id
)

SELECT 
    *,
    CASE 
        WHEN total_cast > 5 AND total_companies > 0 THEN 'Well-Equipped Movie'
        WHEN total_cast = 0 THEN 'Empty Film'
        ELSE 'Standard Movie'
    END AS movie_status
FROM 
    FinalBenchmark
WHERE 
    (production_year >= 1990 AND production_year <= 2023)
    AND (title LIKE '%Adventure%' OR title LIKE '%Drama%')
ORDER BY 
    total_cast DESC, production_year ASC
LIMIT 50 OFFSET 0;
