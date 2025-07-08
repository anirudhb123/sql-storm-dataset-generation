WITH Movie_Details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_count,
        AVG(mk.keyword_length) AS avg_keyword_length
    FROM
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        (SELECT 
            movie_id, 
            LENGTH(keyword) AS keyword_length 
         FROM 
            movie_keyword MK
         JOIN 
            keyword k ON MK.keyword_id = k.id) mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
Top_Movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count, 
        roles_count, 
        avg_keyword_length,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC, roles_count DESC) AS rn
    FROM 
        Movie_Details
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cn.name, 'Unknown') AS company_name,
    tm.cast_count,
    tm.roles_count,
    tm.avg_keyword_length,
    (SELECT COUNT(DISTINCT c2.person_id) 
     FROM cast_info c2 
     WHERE c2.movie_id = tm.movie_id AND c2.note IS NULL) AS null_note_count
FROM 
    Top_Movies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    tm.rn <= 10
ORDER BY 
    tm.cast_count DESC;
