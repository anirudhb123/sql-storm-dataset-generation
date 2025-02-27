WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t 
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id 
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id 
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id 
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id 
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        rm.actor_names,
        rm.keywords
    FROM 
        RankedMovies rm
    WHERE 
        rm.actor_count > 5
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.actor_count,
    fm.actor_names,
    STRING_AGG(fm.keywords, ', ') AS all_keywords
FROM 
    FilteredMovies fm 
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, fm.actor_count, fm.actor_names
ORDER BY 
    fm.production_year DESC, fm.actor_count DESC;
