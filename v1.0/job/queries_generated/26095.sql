WITH MovieActorInfo AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        r.role AS actor_role,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        cast_info ci
    INNER JOIN aka_name a ON ci.person_id = a.person_id
    INNER JOIN title t ON ci.movie_id = t.id
    INNER JOIN role_type r ON ci.role_id = r.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        a.name, t.title, t.production_year, r.role
),

MovieCompanyInfo AS (
    SELECT 
        t.title AS movie_title,
        COMPANY.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    INNER JOIN title t ON mc.movie_id = t.id
    INNER JOIN company_name COMPANY ON mc.company_id = COMPANY.id
    INNER JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE 
        COMPANY.country_code = 'USA'
),

CombinedInfo AS (
    SELECT 
        mai.actor_name,
        mai.movie_title,
        mai.production_year,
        mai.actor_role,
        mai.keyword_count,
        mci.company_name,
        mci.company_type
    FROM 
        MovieActorInfo mai
    LEFT JOIN MovieCompanyInfo mci ON mai.movie_title = mci.movie_title
)

SELECT 
    actor_name, 
    movie_title, 
    production_year, 
    actor_role, 
    keyword_count, 
    company_name, 
    company_type
FROM 
    CombinedInfo
ORDER BY 
    production_year DESC, 
    actor_name ASC;

This query provides a detailed benchmark of string processing by combining movie actor details with the production companies, filtered by the U.S. companies, and aggregates relevant information such as the number of keywords associated with the films. The final output sorts the results by the year of production in descending order and actor names in ascending order for better readability and analysis.
