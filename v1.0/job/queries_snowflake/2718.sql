
WITH recent_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        ROW_NUMBER() OVER (PARTITION BY kt.kind ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    WHERE 
        t.production_year >= 2010
),
cast_details AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        rt.role AS role,
        COUNT(c.id) OVER (PARTITION BY c.movie_id) AS total_cast
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
),
movies_with_cast AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind,
        cd.actor_name,
        cd.role,
        cd.total_cast
    FROM 
        recent_movies rm
    LEFT JOIN 
        cast_details cd ON rm.movie_id = cd.movie_id
),
keyword_movies AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mwc.movie_id,
    mwc.title,
    mwc.production_year,
    mwc.kind,
    mwc.actor_name,
    mwc.role,
    mwc.total_cast,
    COALESCE(km.keywords, 'No keywords') AS keywords
FROM 
    movies_with_cast mwc
LEFT JOIN 
    keyword_movies km ON mwc.movie_id = km.movie_id
WHERE 
    mwc.production_year = (
        SELECT MAX(production_year)
        FROM recent_movies
    )
ORDER BY 
    mwc.production_year DESC, 
    mwc.kind,
    mwc.title;
