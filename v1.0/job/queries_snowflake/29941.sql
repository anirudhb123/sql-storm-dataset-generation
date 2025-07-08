
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY LENGTH(k.keyword) DESC) AS keyword_rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
TopRankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        keyword_rank <= 3
),
CastInfo AS (
    SELECT 
        ci.movie_id,
        ci.person_role_id,
        c.role,
        COUNT(ci.person_id) AS number_of_cast
    FROM 
        cast_info ci
    JOIN 
        role_type c ON ci.person_role_id = c.id
    GROUP BY 
        ci.movie_id, ci.person_role_id, c.role
)
SELECT 
    tr.movie_id,
    tr.title,
    tr.production_year,
    LISTAGG(ri.role || ' (' || ci.number_of_cast || ')', ', ') WITHIN GROUP (ORDER BY ci.number_of_cast DESC) AS cast_info
FROM 
    TopRankedMovies tr
JOIN 
    CastInfo ci ON tr.movie_id = ci.movie_id
JOIN 
    role_type ri ON ci.person_role_id = ri.id
GROUP BY 
    tr.movie_id, tr.title, tr.production_year
ORDER BY 
    tr.production_year DESC, tr.title;
