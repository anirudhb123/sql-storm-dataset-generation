
WITH ranked_titles AS (
    SELECT 
        at.title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY at.production_year DESC) AS rn
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
),
actor_movie_count AS (
    SELECT 
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
    ORDER BY 
        movie_count DESC
    LIMIT 10
),
title_keywords AS (
    SELECT 
        at.title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        at.title
),
actor_info AS (
    SELECT 
        ak.name,
        pi.info AS bio
    FROM 
        aka_name ak
    JOIN 
        person_info pi ON ak.person_id = pi.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
)
SELECT 
    rt.title,
    rt.production_year,
    rt.actor_name,
    akc.movie_count AS total_movies,
    tk.keywords,
    ai.bio
FROM 
    ranked_titles rt
JOIN 
    actor_movie_count akc ON rt.actor_name = akc.name
LEFT JOIN 
    title_keywords tk ON rt.title = tk.title
LEFT JOIN 
    actor_info ai ON rt.actor_name = ai.name
WHERE 
    rt.rn = 1
ORDER BY 
    rt.production_year DESC, akc.movie_count DESC;
