
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info c ON mc.movie_id = c.movie_id
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
person_info_summary AS (
    SELECT 
        pi.person_id,
        STRING_AGG(DISTINCT pi.info, '; ') AS person_info
    FROM 
        person_info pi
    JOIN 
        name n ON pi.person_id = n.imdb_id
    GROUP BY 
        pi.person_id
),
final_summary AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.cast_count,
        ks.keywords,
        pis.person_info
    FROM 
        ranked_titles rt
    LEFT JOIN 
        keyword_summary ks ON rt.title_id = ks.movie_id
    LEFT JOIN 
        cast_info c ON rt.title_id = c.movie_id
    LEFT JOIN 
        person_info_summary pis ON c.person_id = pis.person_id
)
SELECT 
    title,
    production_year,
    cast_count,
    COALESCE(keywords, 'No keywords available') AS keywords,
    COALESCE(person_info, 'No additional info') AS person_info
FROM 
    final_summary
ORDER BY 
    cast_count DESC,
    production_year DESC
LIMIT 20;
