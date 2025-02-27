WITH CTE_Movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors_list
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
CTE_Full_Movie_Info AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.cast_count,
        m.actors_list,
        COALESCE(mi.info, 'No Synopsis Available') AS synopsis,
        COALESCE(ki.keyword, 'No Keywords') AS keywords
    FROM 
        CTE_Movies m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'synopsis')
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_count,
    f.actors_list,
    f.synopsis,
    STRING_AGG(DISTINCT f.keywords, ', ') AS all_keywords
FROM 
    CTE_Full_Movie_Info f
GROUP BY 
    f.movie_id, f.title, f.production_year, f.cast_count, f.actors_list, f.synopsis
HAVING 
    f.cast_count > 5 OR f.production_year = (SELECT MAX(production_year) FROM aka_title)
ORDER BY 
    f.production_year DESC, f.cast_count DESC;
