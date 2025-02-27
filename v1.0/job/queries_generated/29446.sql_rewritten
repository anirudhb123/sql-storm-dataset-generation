WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT cp.kind, ', ') AS company_kinds
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type cp ON mc.company_type_id = cp.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
HighCastMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count, 
        actor_names,
        company_kinds,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        cast_count >= 5  
)
SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    h.cast_count,
    h.actor_names,
    h.company_kinds
FROM 
    HighCastMovies h
JOIN 
    movie_info mi ON h.movie_id = mi.movie_id 
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'description')  
ORDER BY 
    h.rank, h.production_year DESC;