WITH movie_stats AS (
    SELECT 
        at.title AS movie_title,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS has_note_ratio,
        MAX(ci.nr_order) AS max_order,
        MIN(ci.nr_order) AS min_order
    FROM
        aka_title at
    LEFT JOIN 
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        at.title
),
top_movies AS (
    SELECT 
        movie_title,
        cast_count,
        has_note_ratio,
        max_order,
        min_order,
        DENSE_RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        movie_stats
    WHERE 
        cast_count > 0
),
ranked_titles AS (
    SELECT 
        tm.*,
        CASE 
            WHEN has_note_ratio > 0.5 THEN 'High Note' 
            ELSE 'Low Note' 
        END AS note_category
    FROM 
        top_movies tm
)
SELECT 
    rt.movie_title,
    rt.cast_count,
    rt.has_note_ratio,
    rt.max_order,
    rt.min_order,
    rt.note_category,
    STRING_AGG(DISTINCT ka.name, ', ') AS aka_names,
    STRING_AGG(DISTINCT DISTINCT k.keyword, ', ') AS keywords
FROM 
    ranked_titles rt
LEFT JOIN 
    aka_name ka ON rt.movie_title ILIKE '%' || ka.name || '%' 
LEFT JOIN 
    movie_keyword mk ON mk.movie_id IN (SELECT id FROM aka_title WHERE title = rt.movie_title)
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    rt.rank <= 10
    AND (rt.min_order IS NULL OR rt.max_order > rt.min_order)
GROUP BY 
    rt.movie_title, rt.cast_count, rt.has_note_ratio, rt.max_order, rt.min_order, rt.note_category
ORDER BY 
    rt.cast_count DESC, rt.movie_title;

This query performs a performance benchmark on movies based on their cast statistics (via the `complete_cast`, `cast_info`, and `aka_title` tables), while filtering and aggregating data. It utilizes Common Table Expressions (CTEs), string aggregation, and logical conditions to create a ranking of the top movies, based on the number of distinct cast members and other statistics, ensuring the inclusion of various SQL features like outer joins, correlated subqueries, and NULL logic.
