WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS actor_count,
        AVG(pi.info_length) OVER (PARTITION BY t.id) AS avg_info_length
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        (SELECT 
            movie_id, 
            LENGTH(info) AS info_length 
         FROM 
            movie_info) pi ON pi.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count,
        coalesce(mb.company_count, 0) AS company_count,
        rm.avg_info_length
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCompanies mb ON rm.title_id = mb.movie_id
)
SELECT 
    *,
    CASE 
        WHEN actor_count > 10 AND company_count > 5 THEN 'Blockbuster'
        WHEN actor_count <= 10 AND actor_count > 0 THEN 'Indie Film'
        ELSE 'Unknown Genre'
    END AS film_category
FROM 
    FinalResults
WHERE 
    avg_info_length > 50
ORDER BY 
    production_year DESC, actor_count DESC;
