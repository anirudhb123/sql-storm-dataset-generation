WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY tl.count DESC) AS title_rank,
        COUNT(DISTINCT ci.person_id) AS count
    FROM 
        title t
    LEFT JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        (SELECT movie_id, COUNT(*) AS count
         FROM movie_keyword mk
         GROUP BY mk.movie_id) AS tl ON t.id = tl.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
StudentRankings AS (
    SELECT
        COUNT(DISTINCT c.id) AS student_count,
        AVG(CASE WHEN p.gender = 'F' THEN 1 ELSE NULL END) AS female_percentage
    FROM 
        person_info p
    LEFT JOIN
        cast_info c ON p.person_id = c.person_id
    WHERE 
        p.info_type_id = (SELECT id FROM info_type WHERE info = 'student')
        AND c.person_id IS NOT NULL
),
FilteredTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.title_rank <= 5
)
SELECT 
    ft.title,
    ft.production_year,
    COALESCE(st.student_count, 0) AS student_count,
    COALESCE(st.female_percentage, 0) AS female_film_percentage,
    CASE 
        WHEN ft.production_year >= 2000 THEN 'Modern Era'
        WHEN ft.production_year < 2000 THEN 'Classic Era'
        ELSE 'Unknown Era'
    END AS era
FROM 
    FilteredTitles ft
FULL OUTER JOIN 
    StudentRankings st ON TRUE
ORDER BY 
    ft.production_year DESC, 
    ft.title ASC;

