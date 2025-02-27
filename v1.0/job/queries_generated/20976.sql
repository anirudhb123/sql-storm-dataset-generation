WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year,
        COUNT(*) OVER () AS total_movies
    FROM 
        aka_title t
    WHERE 
        (t.title IS NOT NULL AND LENGTH(t.title) > 3) 
        OR (t.production_year IS NOT NULL AND t.production_year BETWEEN 1900 AND EXTRACT(YEAR FROM CURRENT_DATE))
),
ActorRoles AS (
    SELECT 
        a.name,
        c.note AS role_note,
        COUNT(c.person_id) AS num_movies
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    WHERE 
        a.name NOT LIKE '%unknown%' 
        AND (c.note IS NOT NULL OR c.note <> '')
    GROUP BY 
        a.name, c.note
    HAVING 
        COUNT(c.movie_id) > 5
),
FilteredCompanies AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name ASC) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code = 'USA'
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.name AS actor_name,
        ar.role_note,
        fc.company_names,
        rm.rank_per_year,
        (SELECT COUNT(*) FROM movie_companies WHERE movie_id = rm.movie_id) AS company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ar.name)
    LEFT JOIN 
        FilteredCompanies fc ON rm.movie_id = fc.movie_id
    WHERE 
        rm.rank_per_year <= 5
        AND (ar.num_movies IS NULL OR ar.num_movies > 10)
)

SELECT 
    title,
    production_year,
    actor_name,
    company_names,
    COALESCE(role_note, 'Unspecified Role') AS role_note,
    CASE 
        WHEN rank_per_year <= 3 THEN 'Top Ranked'
        ELSE 'Other'
    END AS ranking_category,
    company_count > 0 AS has_company_info
FROM 
    FinalResults
WHERE 
    COALESCE(company_names, '') <> ''
ORDER BY 
    production_year DESC, title ASC;
