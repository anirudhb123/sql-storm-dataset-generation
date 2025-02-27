WITH ranked_titles AS (
    SELECT 
        a.id AS title_id,
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
cast_details AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT CONCAT(p.name, ' (', r.role, ')'), ', ') AS cast_list
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        c.movie_id
),
movie_statistics AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(t.title, 'Unknown Title') AS title,
        COALESCE(t.production_year, 0) AS year,
        COALESCE(c.total_cast, 0) AS number_of_cast_members,
        COALESCE(c.cast_list, 'No Cast Info') AS cast_details,
        k.keyword AS movie_keyword
    FROM 
        title m
    LEFT JOIN 
        ranked_titles t ON m.id = t.title_id
    LEFT JOIN 
        cast_details c ON m.id = c.movie_id
    LEFT JOIN 
        movie_keyword k ON m.id = k.movie_id
)
SELECT 
    ms.title,
    ms.year,
    ms.number_of_cast_members,
    ms.cast_details,
    STRING_AGG(DISTINCT ms.movie_keyword, ', ') AS keywords
FROM 
    movie_statistics ms
GROUP BY 
    ms.title, ms.year, ms.number_of_cast_members, ms.cast_details
ORDER BY 
    ms.year DESC, ms.number_of_cast_members DESC;
