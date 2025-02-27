WITH ActorMovies AS (
    SELECT 
        ka.name AS actor_name,
        COUNT(DISTINCT ct.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, '; ') AS movie_titles,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_name ka
    JOIN 
        cast_info ct ON ka.person_id = ct.person_id
    JOIN 
        aka_title t ON ct.movie_id = t.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        ka.name
),
MovieInfo AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ct.kind AS company_type,
        c.name AS company_name
    FROM 
        aka_title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
Results AS (
    SELECT 
        am.actor_name,
        am.movie_count,
        am.movie_titles,
        mi.movie_title,
        mi.production_year,
        mi.company_type,
        mi.company_name
    FROM 
        ActorMovies am
    JOIN 
        MovieInfo mi ON am.movie_titles LIKE '%' || mi.movie_title || '%'
)
SELECT 
    actor_name,
    movie_count,
    movie_titles,
    COUNT(DISTINCT movie_title) AS unique_movie_count,
    ARRAY_AGG(DISTINCT movie_title) AS movies_in_common
FROM 
    Results
GROUP BY 
    actor_name, movie_count, movie_titles
ORDER BY 
    unique_movie_count DESC, actor_name ASC;
