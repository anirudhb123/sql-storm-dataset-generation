
WITH RecursiveGenreRanking AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.id) AS genre_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
), ActorRoleStats AS (
    SELECT 
        c.movie_id,
        a.person_id,
        COUNT(DISTINCT c.role_id) AS distinct_roles,
        COUNT(c.id) AS total_cast,
        (COUNT(c.id) * 1.0 / NULLIF(COUNT(c.id), 0)) AS role_ratio
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.person_id
), MovieCompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS distinct_companies,
        LISTAGG(DISTINCT com.name, ', ') WITHIN GROUP (ORDER BY com.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name com ON mc.company_id = com.id
    GROUP BY 
        mc.movie_id
), CombinedStats AS (
    SELECT
        t.title,
        t.production_year,
        g.keyword,
        a.distinct_roles,
        a.total_cast,
        a.role_ratio,
        m.distinct_companies,
        m.company_names,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.role_ratio DESC) AS ranked_role_ratio,
        COALESCE(m.company_names, 'Unknown Company') AS display_company_names
    FROM 
        aka_title t
    LEFT JOIN 
        ActorRoleStats a ON t.id = a.movie_id
    LEFT JOIN 
        MovieCompanyStats m ON t.id = m.movie_id
    LEFT JOIN 
        RecursiveGenreRanking g ON t.id = g.title_id
    WHERE 
        t.production_year >= 1990
        AND (m.distinct_companies IS NULL OR m.distinct_companies > 1)
)
SELECT 
    title,
    production_year,
    LISTAGG(DISTINCT CONCAT('Genre: ', keyword), '; ') AS genres,
    SUM(distinct_roles) AS total_distinct_roles,
    AVG(role_ratio) AS average_role_ratio,
    MAX(distinct_companies) AS max_distinct_companies,
    display_company_names
FROM 
    CombinedStats
WHERE
    ranked_role_ratio <= 5
GROUP BY 
    title, production_year, display_company_names
ORDER BY 
    production_year DESC,
    average_role_ratio DESC
LIMIT 100;
