
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS main_actor,
        LISTAGG(a2.name, ', ') WITHIN GROUP (ORDER BY a2.name) AS supporting_actors,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id AND ci.nr_order = 1
    LEFT JOIN 
        cast_info ci2 ON t.id = ci2.movie_id AND ci2.nr_order > 1
    LEFT JOIN 
        aka_name a2 ON ci2.person_id = a2.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        cn.country_code = 'USA' AND 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
ranked_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        main_actor,
        supporting_actors,
        keywords,
        RANK() OVER (ORDER BY production_year DESC) AS rank
    FROM 
        movie_details
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.main_actor,
    rm.supporting_actors,
    rm.keywords
FROM 
    ranked_movies rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, rm.title;
