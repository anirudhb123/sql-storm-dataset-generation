WITH RecursiveMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(a.name, 'Unknown') AS actor_name,
        RANK() OVER (PARTITION BY m.id ORDER BY c.nr_order) AS actor_rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies,
        COUNT(DISTINCT cn.id) AS company_count
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_name,
        rm.actor_rank,
        ci.companies,
        ci.company_count,
        CASE 
            WHEN ci.company_count IS NULL THEN 'No Companies Listed'
            ELSE CAST(ci.company_count AS TEXT) || ' Companies Involved'
        END AS company_status
    FROM 
        RecursiveMovies rm
    LEFT JOIN 
        CompanyInfo ci ON rm.movie_id = ci.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_name,
    md.actor_rank,
    md.companies,
    md.company_count,
    md.company_status,
    COALESCE(ki.keyword, 'No Keywords') AS movie_keyword
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    md.production_year BETWEEN 2000 AND 2023
    AND (md.company_count IS NULL OR md.company_count > 1)
ORDER BY 
    md.production_year DESC,
    md.actor_rank ASC;
