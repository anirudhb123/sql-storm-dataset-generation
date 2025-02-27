
WITH ranked_titles AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_member_count,
        AVG(mi.info_length) AS avg_info_length,
        a.id AS movie_id
    FROM aka_title a
    JOIN complete_cast cc ON a.id = cc.movie_id
    JOIN cast_info c ON cc.subject_id = c.id
    LEFT JOIN (
        SELECT 
            movie_id, 
            LENGTH(info) AS info_length
        FROM movie_info
    ) mi ON mi.movie_id = a.id
    WHERE a.production_year >= 2000
    GROUP BY a.id, a.title, a.production_year
),
titles_with_keywords AS (
    SELECT 
        rt.title, 
        rt.production_year, 
        rt.cast_member_count, 
        rt.avg_info_length, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM ranked_titles rt
    JOIN movie_keyword mk ON rt.movie_id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY rt.title, rt.production_year, rt.cast_member_count, rt.avg_info_length
)
SELECT 
    twk.title,
    twk.production_year,
    twk.cast_member_count,
    twk.avg_info_length,
    twk.keywords
FROM titles_with_keywords twk
WHERE twk.cast_member_count > 5
ORDER BY twk.production_year DESC, twk.cast_member_count DESC;
