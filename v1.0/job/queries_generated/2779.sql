WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
MovieActors AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        COUNT(*) AS num_roles
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id, a.name
), 
HighRoleMovies AS (
    SELECT 
        ma.movie_id,
        ma.actor_name,
        ma.num_roles,
        COALESCE(rm.rank_year, 0) AS year_rank
    FROM 
        MovieActors ma
    LEFT JOIN 
        RankedMovies rm ON ma.movie_id = rm.movie_id
    WHERE 
        ma.num_roles >= 3
    ORDER BY 
        year_rank DESC
)
SELECT 
    hm.movie_id,
    hm.actor_name,
    hm.num_roles,
    COALESCE(i.info, 'No Info') AS additional_info,
    GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords
FROM 
    HighRoleMovies hm
LEFT JOIN 
    movie_info i ON hm.movie_id = i.movie_id AND i.info_type_id = (SELECT id FROM info_type WHERE info = 'description')
LEFT JOIN 
    movie_keyword mk ON hm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    hm.movie_id, hm.actor_name, hm.num_roles, i.info
HAVING 
    COUNT(DISTINCT kw.keyword) > 1
ORDER BY 
    hm.num_roles DESC, hm.movie_id ASC;
