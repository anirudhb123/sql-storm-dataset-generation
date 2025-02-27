WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (
            SELECT id 
            FROM kind_type 
            WHERE kind LIKE 'movie%'
        )
),
distinct_cast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS unique_cast_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
relevant_info AS (
    SELECT 
        m.title_id,
        m.info,
        COALESCE(m.note, 'No Note') AS note,
        i.info_type_id
    FROM 
        movie_info m
    LEFT JOIN 
        info_type i ON m.info_type_id = i.id
    WHERE 
        m.info LIKE '%award%'
),
final_movies AS (
    SELECT 
        rt.title,
        rt.production_year,
        dc.unique_cast_count,
        COALESCE(ri.info, 'No Relevant Info') AS award_info,
        RANK() OVER (ORDER BY rt.production_year DESC, dc.unique_cast_count DESC) AS rank_by_cast
    FROM 
        ranked_titles rt
    LEFT JOIN 
        distinct_cast dc ON rt.title_id = dc.movie_id
    LEFT JOIN 
        relevant_info ri ON rt.title_id = ri.title_id
    WHERE 
        rt.title_rank <= 5 AND
        (dc.unique_cast_count IS NULL OR dc.unique_cast_count > 3)
)
SELECT 
    f.title,
    f.production_year,
    f.unique_cast_count,
    f.award_info,
    CASE 
        WHEN f.unique_cast_count IS NULL THEN 'Unknown'
        WHEN f.unique_cast_count > 10 THEN 'Epic'
        ELSE 'Standard'
    END AS cast_size_category
FROM 
    final_movies f
WHERE 
    f.rank_by_cast < 10
ORDER BY 
    f.production_year DESC, f.unique_cast_count DESC;
