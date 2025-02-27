
WITH MovieStats AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        COUNT(DISTINCT kc.keyword) AS num_keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
        LEFT JOIN movie_companies mc ON t.id = mc.movie_id
        LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
        LEFT JOIN keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        t.id, t.title, t.production_year
), CastStats AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS actors_list,
        COUNT(DISTINCT c.person_id) AS actor_count,
        MAX(CASE WHEN r.role = 'Director' THEN c.nr_order END) AS director_order
    FROM 
        cast_info c
        INNER JOIN aka_name a ON c.person_id = a.person_id
        LEFT JOIN role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
), MovieRanked AS (
    SELECT 
        ms.title_id,
        ms.title,
        ms.production_year,
        ms.num_companies,
        ms.num_keywords,
        cs.actors_list,
        cs.actor_count,
        cs.director_order,
        RANK() OVER (ORDER BY ms.num_companies DESC, ms.num_keywords DESC) AS rank
    FROM 
        MovieStats ms
        LEFT JOIN CastStats cs ON ms.title_id = cs.movie_id
)
SELECT 
    mr.title,
    mr.production_year,
    COALESCE(mr.actor_count, 0) AS total_actors,
    mr.num_companies,
    mr.num_keywords,
    NL.most_repeated_name,
    CASE 
        WHEN mr.director_order IS NULL THEN 'No Director'
        ELSE CAST(mr.director_order AS VARCHAR)
    END AS director_order,
    CASE 
        WHEN mr.num_keywords > 0 THEN 'Keywords Present' 
        ELSE 'No Keywords' 
    END as keyword_status
FROM 
    MovieRanked mr
    LEFT JOIN (
        SELECT 
            person_id,
            MAX(name) AS most_repeated_name 
        FROM 
            aka_name 
        WHERE 
            person_id IS NOT NULL
        GROUP BY 
            person_id
        HAVING 
            COUNT(name) > 1
    ) NL ON NL.person_id = mr.title_id
WHERE 
    mr.rank <= 10 
ORDER BY 
    mr.rank,
    mr.production_year DESC;
