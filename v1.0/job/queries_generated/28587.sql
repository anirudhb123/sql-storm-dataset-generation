WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
TopMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        ci.person_id,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names
    FROM 
        RankedTitles rt
    JOIN 
        complete_cast cc ON cc.movie_id = rt.title_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        rt.rn <= 5  -- Get top 5 movies per year
    GROUP BY 
        rt.title_id, rt.title, rt.production_year, ci.person_id
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON k.id = mt.keyword_id
    GROUP BY 
        mt.movie_id
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.actor_names,
        mk.keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON mk.movie_id = tm.title_id
)
SELECT 
    title,
    production_year,
    actor_names,
    keywords
FROM 
    MovieDetails
WHERE 
    production_year >= 2000  -- Filtering for movies from 2000 onwards
ORDER BY 
    production_year DESC, 
    title;
