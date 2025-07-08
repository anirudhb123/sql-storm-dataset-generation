
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS movie_rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
DirectorInfo AS (
    SELECT 
        ci.movie_id,
        LISTAGG(a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS directors
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.person_role_id IN (SELECT id FROM role_type WHERE role = 'Director')
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    di.directors,
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    DirectorInfo di ON rm.movie_id = di.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.movie_rank <= 3
ORDER BY 
    rm.production_year DESC, rm.movie_rank;
