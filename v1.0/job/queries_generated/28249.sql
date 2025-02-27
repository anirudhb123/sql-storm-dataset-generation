WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(a.name) AS actor_names,
        k.keyword AS movie_keyword
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genres')
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),

company_details AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        GROUP_CONCAT(mn.name) AS other_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        movie_link ml ON mc.movie_id = ml.movie_id
    JOIN 
        title mn ON ml.linked_movie_id = mn.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)

SELECT 
    md.movie_title,
    md.production_year,
    md.actor_names,
    md.movie_keyword,
    cd.company_name,
    cd.company_type,
    cd.other_movies
FROM 
    movie_details md
JOIN 
    company_details cd ON md.movie_title = cd.movie_id
ORDER BY 
    md.production_year DESC, md.movie_title;
