WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS rank
    FROM 
        aka_title t
    JOIN 
        aka_name a ON t.id = a.id
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        r.role AS role_type,
        p.name AS actor_name,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.person_role_id = r.id
    JOIN 
        name p ON c.person_id = p.imdb_id
    GROUP BY 
        c.movie_id, r.role, p.name
),
MostFrequentKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(*) > 2  -- Selecting only movies with more than two keywords
)
SELECT 
    rm.movie_title,
    rm.production_year,
    cd.actor_name,
    cd.role_type,
    k.keyword,
    k.keyword_count,
    rm.rank
FROM 
    RankedMovies rm
JOIN 
    CastDetails cd ON rm.aka_id = cd.movie_id
JOIN 
    MostFrequentKeywords k ON rm.aka_id = k.movie_id
WHERE 
    rm.rank <= 5     -- Top 5 movies per year
ORDER BY 
    rm.production_year DESC, 
    cd.role_count DESC, 
    k.keyword_count DESC;
