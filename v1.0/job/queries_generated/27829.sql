WITH combined_name_info AS (
    SELECT 
        n.id AS name_id,
        n.name AS full_name,
        n.gender,
        ak.name AS aka_name,
        ak.imdb_index AS aka_imdb_index,
        ak.production_year,
        ak.id AS aka_id
    FROM 
        name n
    LEFT JOIN 
        aka_name ak ON n.id = ak.person_id
),
movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword AS movie_keyword,
        m.name AS company_name,
        c.kind AS company_type
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name m ON mc.company_id = m.id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
),
actor_movie_info AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.note AS cast_note,
        ci.nr_order,
        n.full_name,
        n.id AS actor_id,
        nm.title AS movie_title
    FROM 
        cast_info ci
    JOIN 
        combined_name_info n ON ci.person_id = n.name_id
    JOIN 
        movie_details nm ON ci.movie_id = nm.title_id
)

SELECT 
    ami.actor_id,
    ami.full_name,
    ami.movie_title,
    ami.cast_note,
    ami.nr_order,
    GROUP_CONCAT(DISTINCT mk.movie_keyword) AS keywords,
    COUNT(DISTINCT mc.company_name) AS company_count,
    COUNT(DISTINCT c.kind) AS company_types_count,
    COUNT(DISTINCT ami.movie_id) AS total_movies
FROM 
    actor_movie_info ami
LEFT JOIN 
    movie_keyword mk ON ami.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON ami.movie_id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
WHERE 
    ami.nr_order < 5
GROUP BY 
    ami.actor_id,
    ami.full_name,
    ami.movie_title,
    ami.cast_note,
    ami.nr_order
ORDER BY 
    ami.actor_id, ami.nr_order;
