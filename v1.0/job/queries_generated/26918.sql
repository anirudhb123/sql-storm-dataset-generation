WITH RankedTitles AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
PopularActors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(ci.movie_id) DESC) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(ci.movie_id) > 1
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m_k
    JOIN 
        keyword k ON m_k.keyword_id = k.id
    GROUP BY 
        m.movie_id
)

SELECT 
    rt.movie_title,
    rt.production_year,
    pa.actor_name,
    pa.movie_count,
    mk.keywords
FROM 
    RankedTitles rt
JOIN 
    PopularActors pa ON pa.movie_count > 5
JOIN 
    movie_companies mc ON rt.movie_title = (SELECT title FROM aka_title WHERE movie_id = mc.movie_id LIMIT 1)
JOIN 
    MovieKeywords mk ON mk.movie_id = mc.movie_id
WHERE 
    rt.title_rank <= 10
ORDER BY 
    rt.production_year DESC, 
    pa.movie_count DESC;

This SQL query benchmarks string processing by calculating rankings for movie titles and popular actors while aggregating keywords related to the movies. It employs Common Table Expressions (CTEs) for detailed rankings and aggregates, and filters results to obtain titles, production years, actors with more than five movies, and concatenated keywords.
