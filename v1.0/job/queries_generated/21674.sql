WITH Recursive_Cast AS (
    SELECT 
        ca.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY ca.nr_order) AS actor_order,
        COUNT(*) OVER (PARTITION BY ca.movie_id) AS total_actors
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
),

Movie_Details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        m.production_year,
        COALESCE(k.keyword, 'Unspecified') AS keyword,
        COALESCE(cn.name, 'Unknown Company') AS production_company,
        (SELECT COUNT(DISTINCT ca.person_id) 
         FROM cast_info ca 
         WHERE ca.movie_id = t.id) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, m.production_year, k.keyword, cn.name
    HAVING 
        COUNT(DISTINCT mc.company_id) > 0
),

Benchmarked_Movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keyword,
        md.production_company,
        rc.actor_name,
        rc.actor_order,
        rc.total_actors,
        md.actor_count,
        (rc.total_actors * rc.actor_order / NULLIF(md.actor_count, 0)) AS normalized_actor_score
    FROM 
        Movie_Details md
    LEFT JOIN 
        Recursive_Cast rc ON md.movie_id = rc.movie_id
)

SELECT 
    bm.movie_id,
    bm.title,
    bm.production_year,
    bm.keyword,
    bm.production_company,
    STRING_AGG(bm.actor_name, ', ') AS cast_list,
    AVG(bm.normalized_actor_score) OVER (PARTITION BY bm.movie_id) AS average_normalized_actor_score,
    CASE 
        WHEN COUNT(bm.actor_name) OVER (PARTITION BY bm.movie_id) <= 2 THEN 'Limited Cast'
        WHEN AVG(bm.normalized_actor_score) OVER (PARTITION BY bm.movie_id) > 1 THEN 'High Performer'
        ELSE 'Standard Performer'
    END AS performance_category
FROM 
    Benchmarked_Movies bm
GROUP BY 
    bm.movie_id, bm.title, bm.production_year, bm.keyword, bm.production_company
ORDER BY 
    average_normalized_actor_score DESC, md.production_year DESC
FETCH FIRST 10 ROWS ONLY;
