WITH RecursiveMovieStats AS (
    -- Step 1: Calculate the number of distinct keywords associated with each movie
    SELECT 
        mt.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
),
MovieDetails AS (
    -- Step 2: Gather detailed info about each movie along with the number of their cast members
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COALESCE(COUNT(DISTINCT ci.person_id), 0) AS cast_count,
        COALESCE(ms.keyword_count, 0) AS keyword_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    LEFT JOIN 
        RecursiveMovieStats ms ON at.id = ms.movie_id
    GROUP BY 
        at.id, ms.keyword_count
),
TopMovies AS (
    -- Step 3: Identify the top movies based on the number of cast members 
    -- and exclude those that have fewer than a certain number of keywords
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count
    FROM 
        MovieDetails md
    WHERE 
        md.keyword_count > 0 AND md.cast_count IS NOT NULL
    ORDER BY 
        md.cast_count DESC
    LIMIT 10
),
ActorAwards AS (
    -- Step 4: Assign hypothetical awards to actors based on their roles and movies
    SELECT 
        a.name,
        COUNT(DISTINCT ca.movie_id) AS awards
    FROM 
        aka_name a
    JOIN 
        cast_info ca ON a.person_id = ca.person_id
    JOIN 
        movie_companies mc ON ca.movie_id = mc.movie_id
    WHERE 
        mc.company_type_id IS NOT NULL OR mc.note IS NOT NULL
    GROUP BY 
        a.name
)

-- Putting it all together: Get top movies and their actors' awards
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    COALESCE(aa.awards, 0) AS actor_awards,
    CASE 
        WHEN tm.cast_count > 5 THEN 'Many Casts Featured!'
        ELSE 'Few Casts Featured!'
    END AS cast_description
FROM 
    TopMovies tm
LEFT JOIN 
    ActorAwards aa ON tm.movie_id = aa.movie_id
ORDER BY 
    tm.cast_count DESC;

