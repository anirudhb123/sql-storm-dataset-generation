-- This query benchmarks string processing by extracting and manipulating strings from various tables
-- to analyze the connections and associations between people, movies, and roles.

WITH movie_details AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        GROUP_CONCAT(DISTINCT c.role_id) AS role_ids,
        GROUP_CONCAT(DISTINCT p.info) AS person_infos
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    LEFT JOIN 
        person_info p ON c.person_id = p.person_id
    WHERE 
        a.name IS NOT NULL 
        AND t.title IS NOT NULL
    GROUP BY 
        a.id, t.id
),

keyword_details AS (
    SELECT 
        m.id AS movie_id,
        k.keyword AS movie_keyword
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
),

company_details AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)

SELECT 
    md.aka_name,
    md.movie_title,
    md.production_year,
    ARRAY_AGG(DISTINCT kd.movie_keyword) AS keywords,
    ARRAY_AGG(DISTINCT cd.company_name || ' (' || cd.company_type || ')') AS companies,
    COUNT(DISTINCT md.role_ids) AS distinct_roles,
    STRING_AGG(DISTINCT md.person_infos, ', ') AS info_concat
FROM 
    movie_details md
LEFT JOIN 
    keyword_details kd ON md.aka_id = kd.movie_id
LEFT JOIN 
    company_details cd ON md.movie_title = cd.movie_id
GROUP BY 
    md.aka_name, md.movie_title, md.production_year
ORDER BY 
    md.production_year DESC, md.movie_title;

This query first constructs three common table expressions (CTEs) to aggregate data from the `aka_name`, `cast_info`, `title`, `movie_keyword`, and `movie_companies` tables. It extracts the movie's title, production year, related keywords, and associated companies while also aggregating distinct role IDs and other person information into concatenated strings. The final output presents an organized view of the string manipulations done throughout the process, demonstrating the ability to work with various string data types and relations.
