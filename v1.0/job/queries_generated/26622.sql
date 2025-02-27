WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(p.name, 'Unknown') AS director_name,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT co.name) AS companies,
        ARRAY_AGG(DISTINCT ti.info) AS info_type_data
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ca ON m.id = ca.movie_id
    LEFT JOIN 
        aka_name p ON ca.person_id = p.person_id AND p.person_role_id = (SELECT id FROM role_type WHERE role='Director')
    LEFT JOIN 
        name n ON ca.person_id = n.imdb_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        info_type ti ON mi.info_type_id = ti.id
    WHERE 
        m.production_year >= 2000  -- Filter for movies produced from the year 2000 onwards
    GROUP BY 
        m.id, p.name, m.title, m.production_year
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.director_name,
    STRING_AGG(DISTINCT mh.cast_names, ', ') AS cast,
    STRING_AGG(DISTINCT mh.keywords, ', ') AS keywords,
    STRING_AGG(DISTINCT mh.companies, ', ') AS production_companies,
    STRING_AGG(DISTINCT mh.info_type_data, '; ') AS additional_info
FROM 
    movie_hierarchy mh
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.director_name
ORDER BY 
    mh.production_year DESC, mh.title;
