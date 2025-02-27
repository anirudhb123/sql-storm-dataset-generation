
WITH movie_info_cte AS (
    SELECT
        m.id AS movie_id,
        m.title,
        YEAR(CAST('2024-10-01' AS DATE)) - m.production_year AS age,
        COALESCE(ki.info, 'N/A') AS keyword_info
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_info AS mi ON m.id = mi.movie_id
    LEFT JOIN 
        info_type AS ki ON mi.info_type_id = ki.id
    WHERE 
        m.production_year IS NOT NULL
), ranked_actors AS (
    SELECT
        a.person_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY a.movie_id ORDER BY a.nr_order) AS actor_rank,
        a.movie_id
    FROM 
        cast_info AS a
    JOIN 
        aka_name AS ak ON a.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
), company_actor AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ra.actor_name,
        ra.actor_rank
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        ranked_actors AS ra ON mc.movie_id = ra.movie_id
    WHERE 
        cn.country_code = 'USA' OR cn.country_code IS NULL
), aggregate_movie_data AS (
    SELECT
        m.movie_id,
        m.title,
        COUNT(DISTINCT ca.actor_name) AS total_actors,
        STRING_AGG(DISTINCT ca.company_name, ', ') AS production_companies
    FROM 
        movie_info_cte AS m
    LEFT JOIN 
        company_actor AS ca ON m.movie_id = ca.movie_id
    GROUP BY 
        m.movie_id, m.title
), quirky_pictures AS (
    SELECT
        m.title,
        m.age,
        md.total_actors,
        CASE 
            WHEN m.age < 5 THEN 'Fresh' 
            WHEN m.age BETWEEN 5 AND 10 THEN 'Moderate' 
            ELSE 'Aged' 
        END AS freshness,
        CASE 
            WHEN md.production_companies IS NOT NULL THEN 'Produced' 
            ELSE 'No Company' 
        END AS company_status,
        md.production_companies
    FROM 
        movie_info_cte AS m
    LEFT JOIN 
        aggregate_movie_data AS md ON m.movie_id = md.movie_id
    WHERE
        (m.age > 0 AND m.age < 30) OR 
        (md.total_actors IS NULL AND m.keyword_info LIKE '%comedy%')
)
SELECT
    qp.title,
    qp.age,
    qp.total_actors,
    qp.freshness,
    qp.company_status,
    COALESCE(qp.production_companies, 'Unknown') AS production_companies
FROM 
    quirky_pictures AS qp
ORDER BY 
    qp.age DESC, qp.total_actors DESC NULLS LAST;
