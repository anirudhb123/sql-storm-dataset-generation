WITH movie_titles AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        a.name AS actress_name,
        p.name AS actor_name,
        COUNT(DISTINCT c.person_id) AS total_cast_members
    FROM 
        aka_title AT
    JOIN 
        title m ON m.id = AT.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        cast_info c ON c.movie_id = m.id
    LEFT JOIN 
        aka_name a ON a.person_id = c.person_id AND a.name_pcode_nf IS NOT NULL
    LEFT JOIN 
        name p ON p.id = c.person_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword, a.name, p.name
),
filtered_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actress_name,
        actor_name,
        total_cast_members
    FROM 
        movie_titles
    WHERE 
        actress_name IS NOT NULL
    ORDER BY 
        production_year DESC,
        total_cast_members DESC
    LIMIT 10
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.actress_name,
    f.actor_name,
    f.total_cast_members,
    (SELECT 
         STRING_AGG(DISTINCT k.keyword, ', ') 
     FROM 
         movie_keyword mk
     JOIN 
         keyword k ON k.id = mk.keyword_id
     WHERE 
         mk.movie_id = f.movie_id) AS keywords
FROM 
    filtered_movies f;
