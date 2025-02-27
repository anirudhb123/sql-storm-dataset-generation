WITH MovieCast AS (
    SELECT 
        ct.kind AS cast_type,
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ca.nr_order) AS actor_order
    FROM 
        aka_name a
    JOIN 
        cast_info ca ON a.person_id = ca.person_id
    JOIN 
        aka_title t ON ca.movie_id = t.movie_id
    JOIN 
        comp_cast_type ct ON ca.role_id = ct.id
    WHERE 
        a.name IS NOT NULL AND 
        ct.kind IS NOT NULL 
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS total_keywords,
        MAX(LENGTH(k.keyword)) AS max_keyword_length
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
TitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ti.info AS additional_info
    FROM 
        title t
    LEFT JOIN 
        movie_info_idx ti ON t.id = ti.movie_id 
    WHERE 
        ti.info IS NOT NULL
),
FinalOutput AS (
    SELECT 
        mc.movie_title,
        mc.production_year,
        mc.actor_name,
        mc.actor_order,
        ks.total_keywords,
        ks.max_keyword_length,
        ti.additional_info,
        CASE 
            WHEN ks.total_keywords IS NULL THEN 'No keywords'
            ELSE 'Has keywords'
        END AS keyword_status
    FROM 
        MovieCast mc
    LEFT JOIN 
        KeywordStats ks ON mc.movie_id = ks.movie_id
    LEFT JOIN 
        TitleInfo ti ON mc.movie_title = ti.title 
)

SELECT 
    *,
    CONCAT('Film: ', movie_title, ' | Year: ', production_year, ' | Actor: ', actor_name) AS movie_actor_summary
FROM 
    FinalOutput
WHERE 
    actor_order <= 3
ORDER BY 
    production_year DESC, actor_name
FETCH FIRST 10 ROWS ONLY

