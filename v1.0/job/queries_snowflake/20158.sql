
WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
actor_roles AS (
    SELECT 
        ak.name AS actor_name,
        mt.title AS movie_title,
        rt.role,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title mt ON ci.movie_id = mt.id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ak.name, mt.title, rt.role
),
movies_with_keywords AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mt.id, mt.title
),
highlights AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mw.keywords, 'No Keywords') AS keywords,
        COUNT(ar.movie_count) AS role_count,
        MAX(ar.actor_name) AS lead_actor
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movies_with_keywords mw ON rm.movie_id = mw.movie_id
    LEFT JOIN 
        actor_roles ar ON rm.title = ar.movie_title
    WHERE 
        rm.year_rank = 1
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, mw.keywords
)

SELECT 
    h.title,
    h.production_year,
    h.keywords,
    h.role_count,
    h.lead_actor
FROM 
    highlights h
WHERE 
    h.production_year IS NOT NULL
ORDER BY 
    h.production_year DESC, 
    h.role_count DESC
LIMIT 10;
