
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        title t
    LEFT JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5  
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
TopRatedMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        MM.info AS movie_info,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        rm.actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info MM ON rm.title_id = MM.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.title_id = mk.movie_id
    WHERE 
        MM.info_type_id = 1  
    ORDER BY 
        rm.actor_count DESC
    LIMIT 10  
)
SELECT 
    t.title,
    t.production_year,
    t.actor_count,
    t.movie_info,
    t.keywords
FROM 
    TopRatedMovies t
INNER JOIN 
    aka_title at ON t.title_id = at.movie_id
INNER JOIN 
    company_name cn ON at.movie_id = cn.imdb_id 
WHERE 
    cn.country_code = 'USA'  
ORDER BY 
    t.actor_count DESC;
