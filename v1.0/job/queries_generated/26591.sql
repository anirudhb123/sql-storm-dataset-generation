WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
),
famous_people AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
detailed_cast AS (
    SELECT 
        rc.movie_id,
        STRING_AGG(DISTINCT fp.name, ', ') AS famous_actors,
        COUNT(DISTINCT rc.person_id) AS total_actors,
        STRING_AGG(DISTINCT rc.role_id::text, ', ' ORDER BY rc.role_id) AS roles
    FROM 
        cast_info rc
    LEFT JOIN 
        famous_people fp ON rc.person_id = fp.person_id
    GROUP BY 
        rc.movie_id
),
movie_summary AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword,
        dc.famous_actors,
        dc.total_actors,
        dc.roles,
        rm.keyword_rank
    FROM 
        ranked_movies rm
    LEFT JOIN 
        detailed_cast dc ON rm.movie_id = dc.movie_id
)
SELECT 
    ms.title,
    ms.production_year,
    ms.keyword,
    ms.famous_actors,
    ms.total_actors,
    ms.roles
FROM 
    movie_summary ms
WHERE 
    ms.total_actors > 10
ORDER BY 
    ms.production_year DESC, ms.keyword ASC
LIMIT 50;
