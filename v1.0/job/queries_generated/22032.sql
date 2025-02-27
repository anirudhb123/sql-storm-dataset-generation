WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY c.nr_order) AS title_rank,
        kt.keyword
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    WHERE 
        t.production_year IS NOT NULL
),

actors_with_multiple_roles AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.role_id) AS role_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
    HAVING 
        COUNT(DISTINCT c.role_id) > 1
),

langs_with_note AS (
    SELECT 
        ct.kind AS company_type,
        mk.note,
        COUNT(m.movie_id) AS movie_count
    FROM 
        movie_companies m
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    LEFT JOIN 
        movie_info ms ON m.movie_id = ms.movie_id AND ms.info_type_id = (SELECT id FROM info_type WHERE info = 'Language')
    GROUP BY 
        ct.kind, mk.note
)

SELECT 
    t.title AS movie_title,
    t.production_year,
    rt.keyword AS movie_keyword,
    CASE
        WHEN a.role_count IS NOT NULL THEN 'Multiple Roles'
        ELSE 'Single Role or None'
    END AS role_description,
    l.company_type,
    l.movie_count
FROM 
    ranked_titles rt
LEFT JOIN 
    actors_with_multiple_roles a ON rt.title_id IN (
        SELECT 
            c.movie_id 
        FROM 
            cast_info c 
        WHERE 
            c.person_id = a.person_id
    )
LEFT JOIN 
    langs_with_note l ON rt.title_id IN (
        SELECT 
            m.movie_id 
        FROM 
            movie_companies m 
        LEFT JOIN 
            movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Language')
    )
WHERE 
    rt.title_rank = 1
ORDER BY 
    rt.production_year DESC, 
    movie_title;
