WITH MovieDetails AS (
    SELECT 
        a.title, 
        a.production_year, 
        GROUP_CONCAT(DISTINCT ak.name) AS actor_names,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        a.id
), CompanyDetails AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        complete_cast m ON mc.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
), DetailedStats AS (
    SELECT 
        md.title,
        md.production_year,
        COALESCE(cd.company_count, 0) AS company_count,
        md.actor_names,
        md.keyword_count,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.keyword_count DESC) AS keyword_rank
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.title = cd.movie_id
)
SELECT 
    title, 
    production_year,
    actor_names, 
    company_count,
    keyword_count,
    keyword_rank
FROM 
    DetailedStats
WHERE 
    (company_count > 0 OR keyword_count > 2)
ORDER BY 
    production_year DESC, 
    keyword_rank ASC;
