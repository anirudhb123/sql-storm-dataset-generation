WITH movie_details AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        AVG(CASE 
            WHEN ci.nr_order IS NOT NULL THEN ci.nr_order 
            ELSE 0 END
        ) AS avg_order,
        SUM(CASE 
            WHEN ci.note IS NOT NULL THEN 1 
            ELSE 0 END
        ) AS note_count,
        (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = mt.id) AS company_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        mt.production_year IS NOT NULL 
        AND mt.title IS NOT NULL 
        AND (mt.note IS NULL OR mt.note NOT LIKE '%test%')
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

filtered_movies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY avg_order DESC, title) AS rn
    FROM 
        movie_details
    WHERE 
        keyword_count > 0
)

SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_names,
    f.keyword_count,
    f.avg_order,
    f.note_count,
    f.company_count
FROM 
    filtered_movies f
WHERE 
    f.rn <= 5 
    OR (f.company_count = 0 AND f.note_count > 0)
ORDER BY 
    f.production_year DESC, 
    f.title ASC;

This query achieves the following:
1. It utilizes Common Table Expressions (CTEs) to first gather and aggregate movie details, including cast names, keyword counts, average orders, note counts, and associated company counts.
2. A filtering mechanism is implemented to retain movies that have a certain production year and specific criteria on notes, while counting keywords.
3. The `ROW_NUMBER()` window function is used to rank movies by average orders per production year.
4. The final selection employs a mix of conditions to choose top movies while considering companies and notes, ensuring the output contains a balanced and varied dataset.
5. The use of `STRING_AGG()` for concatenating names ensures clarity in how cast members are presented, while NULL checks are incorporated to avoid erroneous aggregations.
