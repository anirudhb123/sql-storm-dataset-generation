WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        t.production_year,
        COALESCE(MIN(cast.nr_order), 0) AS first_cast_order,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title t
    JOIN 
        title m ON m.id = t.movie_id
    LEFT JOIN 
        cast_info cast ON cast.movie_id = m.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    GROUP BY 
        m.id, t.production_year
    HAVING
        t.production_year > 2000
), 
movie_details AS (
    SELECT 
        mh.movie_id, 
        mh.movie_title,
        mh.production_year,
        mh.first_cast_order,
        mh.company_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.company_count DESC) AS rank_per_year,
        RANK() OVER (ORDER BY mh.first_cast_order) AS overall_rank
    FROM 
        movie_hierarchy mh
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.first_cast_order,
    md.company_count,
    md.rank_per_year,
    md.overall_rank,
    ARRAY_AGG(DISTINCT a.name) AS aka_names,
    COALESCE(SUM(CASE WHEN ki.keyword IS NOT NULL THEN 1 END), 0) AS keyword_count
FROM 
    movie_details md
LEFT JOIN 
    aka_name a ON a.person_id IN (SELECT cast.person_id FROM cast_info cast WHERE cast.movie_id = md.movie_id)
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = md.movie_id
LEFT JOIN 
    keyword ki ON ki.id = mk.keyword_id
WHERE 
    md.first_cast_order < 5
GROUP BY 
    md.movie_id, md.movie_title, md.production_year, md.first_cast_order, md.company_count, md.rank_per_year, md.overall_rank
ORDER BY 
    md.rank_per_year, md.overall_rank;

