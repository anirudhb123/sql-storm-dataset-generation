WITH filtered_movies AS (
    SELECT 
        tit.id AS movie_id,
        tit.title,
        tit.production_year,
        COALESCE(info.info, 'No info') AS movie_info,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title AS tit
    LEFT JOIN 
        movie_info AS info ON tit.id = info.movie_id AND info.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
    LEFT JOIN 
        movie_companies AS mc ON tit.id = mc.movie_id
    LEFT JOIN 
        movie_keyword AS mk ON tit.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        tit.production_year > 2000
    GROUP BY 
        tit.id, tit.title, tit.production_year, info.info
),
filtered_actors AS (
    SELECT 
        an.name AS actor_name,
        cc.movie_id,
        cc.role_id,
        r.role
    FROM 
        cast_info AS cc
    JOIN 
        aka_name AS an ON cc.person_id = an.person_id
    JOIN 
        role_type AS r ON cc.role_id = r.id
    WHERE 
        an.name IS NOT NULL
),
combined AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.movie_info,
        fm.company_count,
        fm.keywords,
        fa.actor_name,
        fa.role
    FROM 
        filtered_movies AS fm
    LEFT JOIN 
        filtered_actors AS fa ON fm.movie_id = fa.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    movie_info,
    company_count,
    keywords,
    STRING_AGG(DISTINCT actor_name || ' (' || role || ')', ', ') AS actor_roles
FROM 
    combined
GROUP BY 
    movie_id, title, production_year, movie_info, company_count, keywords
ORDER BY 
    production_year DESC, title;

