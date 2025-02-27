WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.id) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_summary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(CASE WHEN r.role LIKE 'Lead%' THEN 1 END) AS lead_roles,
        COUNT(CASE WHEN r.role LIKE 'Supporting%' OR r.role IS NULL THEN 1 END) AS supporting_roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
movies_with_info AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mi.info, 'No info available') AS additional_info,
        COALESCE(c.total_cast, 0) AS total_cast,
        COALESCE(c.lead_roles, 0) AS lead_roles,
        COALESCE(c.supporting_roles, 0) AS supporting_roles
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        cast_summary c ON m.id = c.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
),
bizarre_movies AS (
    SELECT 
        DISTINCT m.movie_id,
        m.title,
        m.production_year,
        m.additional_info,
        m.total_cast,
        m.lead_roles,
        m.supporting_roles,
        CASE 
            WHEN m.total_cast > 10 THEN 'Epic Cast'
            WHEN m.lead_roles > 3 THEN 'Star-Studded'
            ELSE 'Intimate'
        END AS movie_type,
        COUNT(DISTINCT mk.keyword) OVER(PARTITION BY m.movie_id) AS keyword_count
    FROM 
        movies_with_info m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
        AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%adventure%')
    WHERE 
        m.production_year > (SELECT AVG(production_year) FROM aka_title)
    ORDER BY 
        m.production_year DESC
)
SELECT 
    bm.movie_id,
    bm.title,
    bm.additional_info,
    bm.movie_type,
    bm.keyword_count,
    COALESCE(bm.total_cast, 0) AS total_cast,
    COALESCE(bm.lead_roles, 0) AS lead_roles
FROM 
    bizarre_movies bm
WHERE 
    bm.total_cast > 5 OR bm.lead_roles >= 2
ORDER BY 
    bm.keyword_count DESC, 
    bm.movie_id ASC;
