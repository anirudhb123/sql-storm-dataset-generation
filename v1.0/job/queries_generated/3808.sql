WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY m.movie_id DESC) AS rank_within_year
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    LEFT JOIN 
        (SELECT 
            movie_id, 
            COUNT(DISTINCT person_id) AS actor_count 
         FROM 
            cast_info 
         GROUP BY 
            movie_id) AS actor_counts ON t.id = actor_counts.movie_id
    WHERE 
        k.keyword ILIKE '%action%'
    ORDER BY 
        t.production_year DESC
),
companies AS (
    SELECT 
        mc.movie_id, 
        c.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
movie_summary AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ac.actor_count, 0) AS total_actors,
        ARRAY_AGG(DISTINCT c.company_name) AS companies
    FROM 
        ranked_movies rm
    LEFT JOIN 
        companies c ON rm.movie_id = c.movie_id
    LEFT JOIN 
        (SELECT 
            movie_id, 
            COUNT(DISTINCT person_id) AS actor_count 
         FROM 
            cast_info 
         GROUP BY 
            movie_id) AS ac ON rm.movie_id = ac.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, ac.actor_count
)
SELECT 
    ms.title,
    ms.production_year,
    ms.total_actors,
    ms.companies,
    CASE 
        WHEN ms.total_actors > 5 THEN 'Ensemble Cast' 
        ELSE 'Small Cast' 
    END AS cast_size_descriptor,
    CURRENT_DATE - ms.production_year AS years_since_release
FROM 
    movie_summary ms
WHERE 
    ms.rank_within_year <= 10
ORDER BY 
    ms.production_year DESC, 
    ms.total_actors DESC;
