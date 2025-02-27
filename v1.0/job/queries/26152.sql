
WITH RECURSIVE MovieTitle AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        r.role AS actor_role,
        ak.name AS actor_name
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    AND 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
), MovieKeyword AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        MovieTitle m
    JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id
), MovieInfo AS (
    SELECT 
        m.movie_id,
        COUNT(mi.info_type_id) AS info_count
    FROM 
        MovieTitle m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
)

SELECT 
    mt.movie_id,
    mt.movie_title,
    mt.production_year,
    mt.company_name,
    mt.actor_name,
    mt.actor_role,
    mk.keywords,
    mi.info_count
FROM 
    MovieTitle mt
LEFT JOIN 
    MovieKeyword mk ON mt.movie_id = mk.movie_id
LEFT JOIN 
    MovieInfo mi ON mt.movie_id = mi.movie_id
ORDER BY 
    mt.production_year DESC, 
    mt.movie_title;
