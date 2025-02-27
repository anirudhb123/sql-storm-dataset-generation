WITH MovieTitles AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS movie_keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id, a.name, t.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
FinalResults AS (
    SELECT 
        mt.movie_title,
        mt.production_year,
        mt.actor_name,
        mt.movie_keywords,
        STRING_AGG(DISTINCT ci.company_name || ' (' || ci.company_type || ')', ', ') AS company_details
    FROM 
        MovieTitles mt
    LEFT JOIN 
        CompanyInfo ci ON mt.movie_title = ci.movie_id
    GROUP BY 
        mt.movie_title, mt.production_year, mt.actor_name, mt.movie_keywords
)
SELECT 
    fr.movie_title,
    fr.production_year,
    fr.actor_name,
    fr.movie_keywords,
    fr.company_details
FROM 
    FinalResults fr
WHERE 
    fr.production_year >= 2000
ORDER BY 
    fr.production_year DESC, fr.movie_title;

This SQL query processes string data from multiple tables within the given schema to gather detailed information about movies, including title, production year, actor names, keywords associated with each movie, and the production companies involved. The output is filtered to include only movies produced from 2000 onward and is ordered by production year and movie title. The use of CTEs (Common Table Expressions) allows for better organization and readability of the query.
