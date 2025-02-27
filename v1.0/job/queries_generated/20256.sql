WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        CASE 
            WHEN rm.production_year < 2000 THEN 'Classic'
            WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
),
TopActors AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(ci.movie_id) AS movies_played,
        RANK() OVER (ORDER BY COUNT(ci.movie_id) DESC) AS actor_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
    HAVING 
        COUNT(ci.movie_id) > 2
),
MoviesWithTopActors AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.cast_count,
        fm.era,
        ta.name AS top_actor
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        cast_info ci ON fm.movie_id = ci.movie_id
    LEFT JOIN 
        TopActors ta ON ci.person_id = ta.person_id
)
SELECT 
    mwta.title,
    mwta.production_year,
    mwta.cast_count,
    mwta.era,
    COALESCE(mwta.top_actor, 'No prominent actor') AS prominent_actor
FROM 
    MoviesWithTopActors mwta
WHERE 
    mwta.era = 'Modern'
ORDER BY 
    mwta.production_year DESC, mwta.cast_count DESC;

-- Additional pivot query for NULL logic and outer joins
SELECT 
    COALESCE(movie.title, 'Unknown Title') AS movie_title,
    COALESCE(name.name, 'Unnamed Actor') AS actor_name,
    COALESCE(company.name, 'Independent') AS company_name,
    COUNT(DISTINCT movie.id) AS total_movies,
    SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
FROM 
    aka_title movie
LEFT JOIN 
    cast_info ci ON movie.id = ci.movie_id
LEFT JOIN 
    aka_name name ON ci.person_id = name.person_id
LEFT JOIN 
    movie_companies mc ON movie.id = mc.movie_id
LEFT JOIN 
    company_name company ON mc.company_id = company.id
GROUP BY 
    movie.title, name.name, company.name
HAVING 
    COUNT(DISTINCT movie.id) > 1
ORDER BY 
    total_movies DESC, movie.title;

-- Using strange semantic edge cases and complex predicates
SELECT 
    mk.movie_id,
    COUNT(DISTINCT mk.keyword_id) AS unique_keywords,
    MIN(mk.keyword_id) FILTER (WHERE TOKENS(mk.keyword_id) IS NULL AND LENGTH(mk.keyword) > 5) AS bizarre_case
FROM 
    movie_keyword mk
WHERE 
    mk.keyword_id IS NOT NULL OR mk.keyword_id IS NULL
GROUP BY 
    mk.movie_id
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 0
ORDER BY 
    unique_keywords DESC;
