
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        g.kind,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    JOIN 
        kind_type g ON t.kind_id = g.id
),
featured_movies AS (
    SELECT 
        m.title,
        COUNT(c.person_id) AS cast_count,
        LISTAGG(DISTINCT CONCAT(a.name, ' as ', r.role), ', ') WITHIN GROUP (ORDER BY a.name) AS cast_details
    FROM 
        ranked_titles m
    JOIN 
        complete_cast cc ON m.title_id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.rank <= 5 
    GROUP BY 
        m.title
),
company_info AS (
    SELECT 
        m.title,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS production_companies
    FROM 
        ranked_titles m
    JOIN 
        movie_companies mc ON m.title_id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        m.title
)
SELECT 
    fm.title,
    fm.cast_count,
    fm.cast_details,
    ci.production_companies,
    fm.cast_count || ' cast members, produced by: ' || COALESCE(ci.production_companies, 'Unknown') AS summary
FROM 
    featured_movies fm
LEFT JOIN 
    company_info ci ON fm.title = ci.title
ORDER BY 
    fm.cast_count DESC, fm.title;
