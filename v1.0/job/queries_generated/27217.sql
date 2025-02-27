WITH ranked_titles AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title a 
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        a.title, a.production_year
),
top_titles AS (
    SELECT 
        title, 
        production_year, 
        actor_count, 
        actors
    FROM 
        ranked_titles
    WHERE 
        rank <= 5
)
SELECT 
    tt.title,
    tt.production_year,
    tt.actor_count,
    tt.actors,
    COALESCE(mk.keyword_count, 0) AS keyword_count,
    COALESCE(rt.role_type, 'Unknown') AS role_type
FROM 
    top_titles tt
LEFT JOIN 
    (SELECT 
        movie_id, COUNT(DISTINCT keyword_id) AS keyword_count 
     FROM 
        movie_keyword 
     GROUP BY 
        movie_id) mk ON mk.movie_id = tt.movie_id
LEFT JOIN 
    (SELECT 
        ci.movie_id, rt.role AS role_type 
     FROM 
        cast_info ci 
     JOIN 
        role_type rt ON ci.role_id = rt.id 
     GROUP BY 
        ci.movie_id, rt.role
    ) rt ON rt.movie_id = tt.movie_id
ORDER BY 
    tt.production_year DESC, 
    tt.actor_count DESC;

