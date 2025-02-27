WITH ranked_movies AS (
    SELECT 
        mt.title, 
        mt.production_year, 
        COUNT(DISTINCT c.person_id) AS num_actors,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title mt
    JOIN 
        cast_info c ON mt.id = c.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
actor_fullname AS (
    SELECT 
        ak.name AS actor_name, 
        ak.person_id, 
        COALESCE(NULLIF(ak.name, ''), 'Unknown Actor') AS safe_name
    FROM 
        aka_name ak
    WHERE 
        ak.name IS NOT NULL
),
movie_actor_details AS (
    SELECT 
        rm.title AS movie_title,
        rm.production_year,
        af.actor_name,
        af.safe_name,
        COALESCE(cm.name, 'Independent') AS company_name
    FROM 
        ranked_movies rm
    LEFT JOIN 
        cast_info ci ON rm.id = ci.movie_id
    LEFT JOIN 
        actor_fullname af ON ci.person_id = af.person_id
    LEFT JOIN 
        movie_companies mc ON rm.id = mc.movie_id
    LEFT JOIN 
        company_name cm ON mc.company_id = cm.id
    WHERE 
        rm.rank <= 5 AND rm.production_year >= 2000
),
actor_stats AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS movies_appeared,
        AVG(production_year) AS avg_year
    FROM 
        movie_actor_details
    GROUP BY 
        actor_name
    HAVING 
        COUNT(movie_title) > 1
),
bizarre_comparison AS (
    SELECT 
        ast.actor_name,
        wb.rank AS weird_rank
    FROM 
        actor_stats ast
    FULL OUTER JOIN (
        SELECT 
            movie_title, 
            DENSE_RANK() OVER (ORDER BY AVG(m.production_year)::INTEGER + COUNT(m.title) DESC) AS rank
        FROM 
            ranked_movies m
        GROUP BY 
            movie_title
    ) wb ON ast.actor_name = wb.movie_title
)

SELECT 
    mad.movie_title,
    mad.production_year,
    mad.actor_name,
    mad.company_name,
    bs.weird_rank,
    CASE 
        WHEN bs.weird_rank IS NOT NULL THEN 'Ranked'
        WHEN mad.company_name LIKE 'Ind%' THEN 'Indie Film'
        ELSE 'Unranked'
    END AS classification
FROM 
    movie_actor_details mad
LEFT JOIN 
    bizarre_comparison bs ON mad.actor_name = bs.actor_name
ORDER BY 
    mad.production_year DESC, mad.company_name, bs.weird_rank DESC NULLS LAST;
