WITH movie_details AS (
    SELECT 
        t.title as movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) as aka_names,
        GROUP_CONCAT(DISTINCT c.name) as company_names,
        GROUP_CONCAT(DISTINCT k.keyword) as keywords
    FROM 
        title t
    LEFT JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        aka_name ak ON at.id = ak.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 1980 AND 2020
    GROUP BY 
        t.id
),
cast_details AS (
    SELECT 
        t.title as movie_title,
        GROUP_CONCAT(DISTINCT n.name) as actor_names,
        COUNT(DISTINCT c.person_id) as actor_count
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        name n ON c.person_id = n.id
    GROUP BY 
        t.id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.aka_names,
    md.company_names,
    md.keywords,
    cd.actor_names,
    cd.actor_count
FROM 
    movie_details md
LEFT JOIN 
    cast_details cd ON md.movie_title = cd.movie_title
ORDER BY 
    md.production_year DESC, md.movie_title;
