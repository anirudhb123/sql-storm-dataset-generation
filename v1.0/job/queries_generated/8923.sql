WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_ratio,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        person_info pi ON c.person_id = pi.person_id
    LEFT JOIN 
        info_type it ON pi.info_type_id = it.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id 
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id 
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id 
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
top_ranked_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.has_note_ratio
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 10
)
SELECT 
    tr.title,
    tr.production_year,
    COALESCE(g.name, 'Unknown') AS genre,
    tr.total_cast,
    tr.has_note_ratio
FROM 
    top_ranked_movies tr
LEFT JOIN 
    movie_companies mc ON tr.movie_id = mc.movie_id
LEFT JOIN 
    company_name g ON mc.company_id = g.id
ORDER BY 
    tr.production_year DESC, 
    tr.total_cast DESC;
