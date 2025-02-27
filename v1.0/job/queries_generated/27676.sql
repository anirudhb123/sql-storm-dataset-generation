WITH DetailedMovieInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        string_agg(DISTINCT concat(c.role_id, ':', r.role), '; ') AS roles,
        string_agg(DISTINCT k.keyword, ', ') AS keywords,
        string_agg(DISTINCT co.name, ', ') AS companies
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
)

SELECT 
    dmi.movie_id,
    dmi.title,
    dmi.production_year,
    dmi.roles,
    dmi.keywords,
    dmi.companies,
    COUNT(DISTINCT c.id) AS total_cast_members,
    COUNT(DISTINCT k.id) AS total_keywords
FROM 
    DetailedMovieInfo dmi
LEFT JOIN 
    cast_info c ON dmi.movie_id = c.movie_id
LEFT JOIN 
    movie_keyword mk ON dmi.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    dmi.movie_id, dmi.title, dmi.production_year, dmi.roles, dmi.keywords, dmi.companies
ORDER BY 
    dmi.production_year DESC, dmi.title ASC;

This SQL query benchmark queries the `title`, `cast_info`, and other related tables to compile detailed information about movies produced between 2000 and 2023, including their titles, production years, role types, keywords associated with them, and companies associated with their production. The results are grouped to count unique cast members and keywords, providing a robust overview of movie data which can be useful for evaluating string processing capabilities with extensive string aggregation and joins.
