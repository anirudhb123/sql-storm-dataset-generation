WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS movie_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
DirectorsInfo AS (
    SELECT 
        ci.movie_id,
        a.name AS director_name,
        COUNT(ci.person_id) AS num_cast_members
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.person_role_id IS NULL 
    GROUP BY 
        ci.movie_id, a.name
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
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
    d.director_name,
    d.num_cast_members,
    COALESCE(mk.keywords_list, 'No Keywords') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    DirectorsInfo d ON rm.movie_id = d.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.movie_rank = 1 
    AND rm.production_year IS NOT NULL 
ORDER BY 
    rm.production_year DESC, 
    d.num_cast_members DESC;