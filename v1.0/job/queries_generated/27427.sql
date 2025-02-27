WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (ORDER BY m.production_year DESC, total_cast DESC) AS rank
    FROM 
        aka_title ak
    JOIN title m ON ak.movie_id = m.id
    LEFT JOIN cast_info c ON m.id = c.movie_id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),

top_ranked_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        aka_names,
        keywords
    FROM 
        ranked_movies
    WHERE 
        rank <= 10
)

SELECT 
    tr.movie_id,
    tr.title,
    tr.production_year,
    tr.total_cast,
    tr.aka_names,
    tr.keywords,
    COALESCE(mp.info, 'N/A') AS additional_info
FROM 
    top_ranked_movies tr
LEFT JOIN (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
) mp ON tr.movie_id = mp.movie_id
ORDER BY 
    tr.total_cast DESC, 
    tr.production_year DESC;
