WITH RecursiveMovieData AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        rn.rn
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        (SELECT ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY id) AS rn, movie_id FROM movie_keyword) rn ON t.id = rn.movie_id
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        c.movie_id,
        c.note,
        NULL AS production_year,
        'Part of a Complete Cast' AS keyword,
        NULL AS rn
    FROM 
        complete_cast c
    WHERE 
        EXISTS (
            SELECT 1
            FROM aka_title t
            WHERE c.movie_id = t.id AND t.production_year < 2000
        )
)

SELECT 
    rmd.movie_id,
    rmd.title,
    rmd.production_year,
    COALESCE(c_person.name, 'Unknown Actor') AS actor_name,
    rmd.keyword AS movie_keyword,
    COUNT(DISTINCT c_role.role) OVER (PARTITION BY rmd.movie_id) AS role_count,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY rmd.movie_id) AS note_count,
    STRING_AGG(DISTINCT ci.note, ', ' ORDER BY ci.nr_order) AS notes
FROM 
    RecursiveMovieData rmd
LEFT JOIN 
    cast_info ci ON rmd.movie_id = ci.movie_id
LEFT JOIN 
    aka_name c_person ON ci.person_id = c_person.person_id
LEFT JOIN 
    role_type c_role ON ci.role_id = c_role.id
WHERE 
    rmd.production_year IS NULL OR rmd.production_year >= 2000
GROUP BY 
    rmd.movie_id, rmd.title, rmd.production_year, c_person.name
HAVING 
    COUNT(DISTINCT ci.id) FILTER (WHERE ci.note IS NOT NULL) > 2
ORDER BY 
    rmd.production_year DESC NULLS LAST, rmd.title;
