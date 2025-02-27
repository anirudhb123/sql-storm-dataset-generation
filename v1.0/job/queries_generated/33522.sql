WITH RECURSIVE hierarchy AS (
    SELECT 
        movie.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        1 AS level
    FROM 
        title
    LEFT JOIN 
        aka_title ON title.id = aka_title.movie_id
    WHERE 
        title.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        movie_companies.movie_id,
        CONCAT(hierarchy.movie_title, ' (Sequel)') AS movie_title,
        hierarchy.production_year + 1,
        level + 1 
    FROM 
        hierarchy
    JOIN 
        movie_companies ON hierarchy.movie_id = movie_companies.movie_id
    WHERE 
        movie_companies.company_type_id IN (SELECT id FROM company_type WHERE kind LIKE 'Production%')
)

SELECT 
    h.movie_id,
    h.movie_title,
    h.production_year,
    COALESCE(cast_list.cast_members, 0) AS total_cast,
    COALESCE(keyword_list.keywords_used, 0) AS total_keywords,
    COUNT(DISTINCT mi.info) AS total_movie_info
FROM 
    hierarchy h
LEFT JOIN (
    SELECT 
        c.movie_id,
        STRING_AGG(a.name, ', ') AS cast_members
    FROM 
        cast_info c 
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
) cast_list ON h.movie_id = cast_list.movie_id
LEFT JOIN (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_used
    FROM 
        movie_keyword mk 
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
) keyword_list ON h.movie_id = keyword_list.movie_id
LEFT JOIN 
    movie_info mi ON h.movie_id = mi.movie_id 
WHERE 
    h.level <= 2 
GROUP BY 
    h.movie_id, h.movie_title, h.production_year, cast_list.cast_members, keyword_list.keywords_used
ORDER BY 
    h.production_year DESC, h.movie_title ASC;

