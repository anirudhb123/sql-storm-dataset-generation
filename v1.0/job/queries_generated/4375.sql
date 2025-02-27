WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY m.company_count DESC) AS rn
    FROM 
        title t
    LEFT JOIN (
        SELECT 
            mc.movie_id,
            COUNT(DISTINCT mc.company_id) AS company_count
        FROM 
            movie_companies mc
        GROUP BY 
            mc.movie_id
    ) m ON t.id = m.movie_id
),
TopRatedMovies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        COALESCE(ki.info, 'No Keywords') AS keyword_info,
        nk.keyword AS movie_keyword
    FROM 
        RankedMovies r
    LEFT JOIN movie_info mi ON r.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN movie_keyword mk ON r.movie_id = mk.movie_id
    LEFT JOIN keyword nk ON mk.keyword_id = nk.id
    LEFT JOIN movie_info_idx ki ON r.movie_id = ki.movie_id
    WHERE 
        r.rn <= 5
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(ka.name, 'Unknown') AS actor_name,
    COALESCE(c.kind, 'No Role') AS character_role,
    t.keyword_info,
    COUNT(DISTINCT ci.id) AS cast_count
FROM 
    TopRatedMovies t
LEFT JOIN 
    cast_info ci ON t.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ka ON ci.person_id = ka.person_id
LEFT JOIN 
    role_type c ON ci.role_id = c.id
GROUP BY 
    t.title, t.production_year, ka.name, c.kind, t.keyword_info
ORDER BY 
    t.production_year DESC, t.title ASC;
