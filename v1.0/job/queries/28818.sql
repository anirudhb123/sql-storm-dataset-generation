
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year > 2000
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
SelectedMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.rank = 1
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
)
SELECT 
    sm.title,
    sm.production_year,
    sm.keywords,
    COUNT(DISTINCT cc.id) AS total_cast,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    SelectedMovies sm
JOIN 
    complete_cast cc ON sm.movie_id = cc.movie_id
JOIN 
    movie_companies mc ON sm.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    cn.country_code = 'USA'
GROUP BY 
    sm.title, sm.production_year, sm.keywords
ORDER BY 
    sm.production_year DESC;
