
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)

SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    ta.name AS top_actor,
    ta.movie_count,
    COALESCE(mkw.keywords, 'No Keywords') AS keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    cast_info ci ON rt.title_id = ci.movie_id
LEFT JOIN 
    TopActors ta ON ci.person_id = ta.person_id
LEFT JOIN 
    MoviesWithKeywords mkw ON rt.title_id = mkw.movie_id
WHERE 
    rt.year_rank <= 3
ORDER BY 
    rt.production_year DESC, 
    ta.movie_count DESC NULLS LAST;
