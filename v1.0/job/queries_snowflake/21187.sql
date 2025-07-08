
WITH RECURSIVE actor_movies AS (
    SELECT 
        ka.person_id,
        COUNT(DISTINCT ct.movie_id) AS total_movies,
        LISTAGG(DISTINCT kt.keyword, ', ') WITHIN GROUP (ORDER BY kt.keyword) AS associated_keywords
    FROM 
        aka_name ka
    JOIN 
        cast_info ct ON ka.person_id = ct.person_id
    JOIN 
        aka_title cat ON ct.movie_id = cat.movie_id
    LEFT JOIN 
        movie_keyword mk ON cat.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        ka.person_id
    HAVING 
        COUNT(DISTINCT ct.movie_id) > 5
),
dramatic_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name), 'Unknown') AS companies,
        SUM(CASE WHEN ct.kind = 'drama' THEN 1 ELSE 0 END) AS drama_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        kind_type ct ON mt.kind_id = ct.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
    HAVING 
        COUNT(DISTINCT mc.company_id) > 0
),
frequent_actors AS (
    SELECT 
        am.person_id, 
        am.total_movies,
        ROW_NUMBER() OVER (ORDER BY am.total_movies DESC) AS rank
    FROM 
        actor_movies am
    WHERE 
        am.total_movies IS NOT NULL
)
SELECT 
    fa.person_id,
    fa.total_movies,
    dm.title,
    dm.production_year,
    dm.companies,
    am.associated_keywords
FROM 
    frequent_actors fa
JOIN 
    actor_movies am ON fa.person_id = am.person_id
LEFT JOIN 
    dramatic_movies dm ON fa.total_movies > dm.drama_count
WHERE 
    fa.rank <= 10
OR 
    (fa.rank = 10 AND dm.production_year IS NOT NULL)
ORDER BY 
    fa.total_movies DESC, 
    dm.production_year DESC
LIMIT 5;
