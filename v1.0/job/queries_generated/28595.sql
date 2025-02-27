WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.company_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5  -- Top 5 movies per production year
),
MovieKeywords AS (
    SELECT 
        tm.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.movie_id
),
MovieInfo AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        mk.keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
)
SELECT 
    mi.movie_id,
    mi.title,
    mi.production_year,
    mi.keywords,
    COALESCE(ai.name, 'Unknown') AS actor_name,
    COUNT(c.id) AS role_count,
    STRING_AGG(DISTINCT rt.role, ', ') AS roles
FROM 
    MovieInfo mi
LEFT JOIN 
    complete_cast cc ON mi.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id AND cc.movie_id = c.movie_id
LEFT JOIN 
    aka_name ai ON c.person_id = ai.person_id
LEFT JOIN 
    role_type rt ON c.role_id = rt.id
GROUP BY 
    mi.movie_id, mi.title, mi.production_year, mi.keywords, ai.name
ORDER BY 
    mi.production_year DESC, role_count DESC;
