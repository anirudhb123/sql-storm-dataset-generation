WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
cast_roles AS (
    SELECT 
        p.id AS person_id,
        a.name AS person_name,
        r.role AS role_name,
        COUNT(CASE WHEN ci.note IS NOT NULL THEN 1 END) AS note_count,
        COALESCE(MAX(ci.nr_order), 0) AS max_order
    FROM 
        cast_info AS ci
    INNER JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    INNER JOIN 
        role_type AS r ON ci.role_id = r.id
    LEFT JOIN 
        person_info AS pi ON a.person_id = pi.person_id
    WHERE 
        a.name IS NOT NULL AND 
        (pi.info IS NULL OR pi.info NOT LIKE '%deceased%')
    GROUP BY 
        p.id, a.name, r.role
),
movie_info_with_keywords AS (
    SELECT 
        t.id AS movie_id, 
        t.title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title
),
final_report AS (
    SELECT 
        rm.rank,
        rm.title,
        rm.production_year,
        rm.cast_count,
        cr.person_name,
        cr.role_name,
        mw.keywords,
        CASE 
            WHEN cr.note_count > 0 THEN 'Notes available'
            ELSE 'No notes available'
        END AS note_status
    FROM 
        ranked_movies rm
    LEFT JOIN 
        cast_roles cr ON rm.rank = cr.max_order
    LEFT JOIN 
        movie_info_with_keywords mw ON rm.title = mw.title
    WHERE 
        rm.cast_count > 5
)
SELECT 
    f.rank,
    f.title,
    f.production_year,
    f.cast_count,
    f.person_name,
    f.role_name,
    f.keywords,
    CASE 
        WHEN f.note_status = 'Notes available' AND (f.person_name IS NULL OR f.role_name IS NULL) THEN 'Incomplete Data'
        ELSE f.note_status
    END AS final_note_status
FROM 
    final_report f
WHERE 
    f.rank <= 10
ORDER BY 
    f.rank;
