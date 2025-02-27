WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year AS year,
        k.keyword AS genre,
        c.kind AS company_type,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, c.kind
),
movie_info_summary AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.year,
        STRING_AGG(DISTINCT COALESCE(mi.info, ''), '; ') AS additional_info
    FROM 
        movie_details md
    LEFT JOIN 
        movie_info mi ON md.movie_id = mi.movie_id
    GROUP BY 
        md.movie_id, md.movie_title, md.year
)

SELECT 
    mi.movie_title,
    mi.year,
    mi.additional_info,
    md.actors,
    COUNT(DISTINCT k.keyword) AS genre_count
FROM 
    movie_info_summary mi
JOIN 
    movie_details md ON mi.movie_id = md.movie_id
JOIN 
    keyword k ON md.genre = k.keyword
GROUP BY 
    mi.movie_title, mi.year, mi.additional_info, md.actors
ORDER BY 
    mi.year DESC, genre_count DESC;
