WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count
    FROM 
        cast_info ci
    INNER JOIN 
        ranked_titles rt ON ci.movie_id = rt.title_id
    GROUP BY 
        ci.movie_id
),
top_cast_movies AS (
    SELECT 
        cd.movie_id,
        cd.distinct_cast_count,
        cd.notes_count,
        rt.title,
        rt.production_year
    FROM 
        cast_details cd
    JOIN 
        ranked_titles rt ON cd.movie_id = rt.title_id
    WHERE 
        cd.distinct_cast_count = (SELECT MAX(distinct_cast_count) FROM cast_details)
),
movies_with_keywords AS (
    SELECT 
        mt.movie_id,
        ARRAY_AGG(mk.keyword) AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword mk ON mt.keyword_id = mk.id
    GROUP BY 
        mt.movie_id
),
final_benchmark AS (
    SELECT 
        t.title,
        t.production_year,
        CASE 
            WHEN t.notes_count IS NULL THEN 'No notes available'
            ELSE CONCAT(t.notes_count, ' note(s) found')
        END AS notes_status,
        kw.keywords,
        t.distinct_cast_count,
        (SELECT COUNT(*) FROM aka_name an WHERE an.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = t.movie_id)) AS inferred_person_count
    FROM 
        top_cast_movies t
    LEFT JOIN 
        movies_with_keywords kw ON t.movie_id = kw.movie_id
)
SELECT 
    title,
    production_year,
    notes_status,
    keywords,
    distinct_cast_count,
    inferred_person_count,
    RANK() OVER (ORDER BY distinct_cast_count DESC, production_year ASC) AS rank_by_cast,
    COALESCE(NULLIF(keywords[1], ''), 'No keywords') AS first_keyword
FROM 
    final_benchmark
WHERE 
    notes_status LIKE '%note%'
ORDER BY 
    production_year DESC, rank_by_cast;

