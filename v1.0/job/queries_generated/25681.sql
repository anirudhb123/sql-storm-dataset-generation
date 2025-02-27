WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT c.person_role_id) AS role_ids,
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
)

SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.aka_names,
    md.role_ids,
    md.num_cast_members,
    md.keywords,
    ARRAY_AGG(DISTINCT c.gender) AS cast_genders,
    COALESCE(NULLIF(ARRAY_AGG(DISTINCT n.name ORDER BY n.name ASC), '{}'), '{"No Cast"}') AS cast_names 
FROM 
    MovieDetails md 
LEFT JOIN 
    complete_cast cc ON md.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.id = ci.movie_id
LEFT JOIN 
    name n ON ci.person_id = n.id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Date of Birth')
GROUP BY 
    md.movie_id, md.movie_title, md.production_year, md.aka_names, md.role_ids, md.num_cast_members, md.keywords
ORDER BY 
    md.production_year DESC, md.movie_title;
