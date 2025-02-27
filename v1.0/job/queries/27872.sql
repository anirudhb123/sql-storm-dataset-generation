
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        title m
    JOIN 
        movie_info mi ON m.id = mi.movie_id
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.actor_count,
        rm.aka_names,
        rm.keywords
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year >= 2000 
        AND rm.actor_count > 3 
        AND rm.keywords LIKE '%action%'
)
SELECT 
    f.movie_id,
    f.movie_title,
    f.production_year,
    f.actor_count,
    f.aka_names,
    f.keywords,
    ct.kind AS company_type
FROM 
    FilteredMovies f
JOIN 
    movie_companies mc ON f.movie_id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
ORDER BY 
    f.production_year DESC, 
    f.actor_count DESC;
