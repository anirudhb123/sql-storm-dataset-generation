WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_per_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS total_cast_members
    FROM 
        aka_title t
    JOIN 
        cast_info c ON c.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
),
movie_with_keywords AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        rk.keyword_count
    FROM 
        ranked_movies r
    LEFT JOIN (
        SELECT 
            movie_id, COUNT(*) AS keyword_count
        FROM 
            movie_keyword
        GROUP BY 
            movie_id
    ) rk ON rk.movie_id = r.movie_id
    WHERE 
        rk.keyword_count > 5 OR rk.keyword_count IS NULL
),
final_output AS (
    SELECT 
        m.title,
        m.production_year,
        m.total_cast_members,
        COALESCE(k.keyword_count, 0) AS keyword_count,
        CASE 
            WHEN m.production_year < 2000 THEN 'Classic'
            WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Contemporary'
        END AS movie_era
    FROM 
        movie_with_keywords m
    LEFT JOIN (
        SELECT 
            k.movie_id,
            COUNT(k.movie_id) AS keyword_count
        FROM 
            movie_keyword k
        WHERE 
            k.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%Drama%' OR keyword LIKE '%Action%')
        GROUP BY 
            k.movie_id
    ) k ON k.movie_id = m.movie_id
)
SELECT 
    fo.title,
    fo.production_year,
    fo.total_cast_members,
    fo.keyword_count,
    fo.movie_era
FROM 
    final_output fo
WHERE 
    fo.total_cast_members > 3 AND 
    (fo.production_year IS NOT NULL AND fo.production_year > 1990)
ORDER BY 
    fo.production_year DESC, 
    fo.keyword_count DESC, 
    fo.title ASC
FETCH FIRST 10 ROWS ONLY; 

