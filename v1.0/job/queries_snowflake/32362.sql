
WITH RECURSIVE movie_cast_hierarchy AS (
    SELECT 
        mc.movie_id, 
        c.person_id, 
        a.name AS actor_name, 
        1 AS level
    FROM 
        complete_cast mc
    JOIN 
        cast_info c ON mc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.nr_order = 1
  
    UNION ALL 
  
    SELECT 
        m.movie_id, 
        c.person_id, 
        a.name AS actor_name, 
        h.level + 1
    FROM 
        complete_cast m
    JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    JOIN 
        cast_info c ON mc.movie_id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        movie_cast_hierarchy h ON h.movie_id = m.movie_id
    WHERE 
        c.nr_order > 1
),
actor_movie_count AS (
    SELECT 
        actor_name, 
        COUNT(DISTINCT movie_id) AS movie_count
    FROM 
        movie_cast_hierarchy
    GROUP BY 
        actor_name
),
movies_with_keywords AS (
    SELECT 
        t.title,
        t.production_year,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title, t.production_year
),
final_result AS (
    SELECT 
        amc.actor_name,
        amc.movie_count,
        mwk.title,
        mwk.production_year,
        mwk.keywords,
        RANK() OVER (PARTITION BY amc.actor_name ORDER BY amc.movie_count DESC) AS actor_rank
    FROM 
        actor_movie_count amc
    LEFT JOIN 
        movies_with_keywords mwk ON amc.movie_count > 5
)
SELECT 
    f.actor_name, 
    f.movie_count, 
    f.title, 
    f.production_year, 
    f.keywords
FROM 
    final_result f
WHERE 
    f.actor_rank = 1 
ORDER BY 
    f.movie_count DESC, f.actor_name;
