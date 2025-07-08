WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
PopularTitles AS (
    SELECT 
        tm.title,
        tm.production_year,
        tk.keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        title tm
    LEFT JOIN 
        movie_keyword mk ON tm.id = mk.movie_id
    LEFT JOIN 
        keyword tk ON mk.keyword_id = tk.id
    GROUP BY 
        tm.id, tm.title, tm.production_year, tk.keyword
    HAVING 
        COUNT(mk.id) > 0
),
TopActors AS (
    SELECT 
        an.name,
        COUNT(distinct ci.movie_id) AS movie_count
    FROM 
        aka_name an
    JOIN 
        cast_info ci ON an.person_id = ci.person_id
    GROUP BY 
        an.name
    HAVING 
        COUNT(distinct ci.movie_id) > 5
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(NULLIF(rm.actor_count, 0), 1) AS actor_count,
    pa.keyword,
    ta.name AS top_actor,
    ta.movie_count
FROM 
    RankedMovies rm
LEFT JOIN 
    PopularTitles pa ON rm.title = pa.title 
    AND rm.production_year = pa.production_year
LEFT JOIN 
    TopActors ta ON ta.movie_count = (SELECT MAX(movie_count) FROM TopActors)
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
