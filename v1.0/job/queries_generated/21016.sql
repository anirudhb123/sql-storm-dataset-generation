WITH recursive movie_cast_summary AS (
    SELECT 
        akn.name AS actor_name,
        akn.person_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY akn.person_id ORDER BY m.production_year DESC) AS year_rank
    FROM 
        aka_name akn
    JOIN 
        cast_info ci ON akn.person_id = ci.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.id
    WHERE 
        m.production_year IS NOT NULL
),
highest_rated_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        AVG(mi.info::float) AS average_rating
    FROM 
        title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        m.id
    HAVING 
        AVG(mi.info::float) > 8 
),
company_statistics AS (
    SELECT 
        co.country_code,
        COUNT(DISTINCT mc.movie_id) AS total_movies,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        co.country_code
    HAVING 
        COUNT(DISTINCT mc.movie_id) > 5
),
eventful_movies AS (
    SELECT 
        m.title,
        SUM(CASE WHEN mi.note IS NULL THEN 1 ELSE 0 END) AS missing_notes,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
    GROUP BY 
        m.title
    HAVING 
        SUM(CASE WHEN mi.note IS NULL THEN 1 ELSE 0 END) > 2
)

SELECT 
    mcs.actor_name,
    mcs.movie_title,
    mcs.production_year,
    hr.average_rating,
    cs.country_code,
    cs.total_movies,
    cs.total_companies,
    em.missing_notes,
    em.keyword_count
FROM 
    movie_cast_summary mcs
LEFT JOIN 
    highest_rated_movies hr ON mcs.movie_title = hr.title
LEFT JOIN 
    company_statistics cs ON mcs.movie_title IN (SELECT title FROM aka_title WHERE id IN (SELECT movie_id FROM cast_info WHERE person_id = mcs.person_id))
LEFT JOIN 
    eventful_movies em ON mcs.movie_title = em.title
WHERE 
    mcs.year_rank = 1
ORDER BY 
    mcs.actor_name ASC, mcs.production_year DESC;
