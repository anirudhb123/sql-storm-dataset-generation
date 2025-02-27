WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COALESCE(MIN(mi.info), 'No info available') AS movie_info
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        t.production_year >= 2000 
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
), 
actor_details AS (
    SELECT 
        p.id AS person_id,
        ak.name AS actor_name,
        ak.imdb_index AS actor_index
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    WHERE 
        t.production_year >= 2000
)
SELECT 
    md.movie_title,
    md.production_year,
    md.company_type,
    md.aka_names,
    md.keywords,
    md.movie_info,
    ad.actor_name,
    ad.actor_index
FROM 
    movie_details md
LEFT JOIN 
    actor_details ad ON md.movie_title IN (
        SELECT t.title 
        FROM title t 
        JOIN cast_info ci ON ci.movie_id = t.id 
        WHERE ci.person_id = ad.person_id
    )
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
