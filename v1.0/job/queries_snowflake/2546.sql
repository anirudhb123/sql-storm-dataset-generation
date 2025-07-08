
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
TopActors AS (
    SELECT 
        a.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.name
    HAVING 
        COUNT(ci.movie_id) > 10
    ORDER BY 
        movie_count DESC
    LIMIT 5
)
SELECT 
    rt.title,
    rt.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    ta.name AS top_actor,
    ta.movie_count
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieKeywords mk ON rt.title_id = mk.movie_id
JOIN 
    TopActors ta ON ta.movie_count > 10
WHERE 
    rt.title_rank <= 3
    AND (rt.production_year % 2 = 0 OR rt.production_year IS NULL)
ORDER BY 
    rt.production_year DESC, 
    rt.title;
