
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
TopMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        LISTAGG(rt.keyword, ', ') WITHIN GROUP (ORDER BY rt.keyword) AS keywords
    FROM 
        RankedTitles rt
    WHERE 
        rt.keyword_rank <= 5
    GROUP BY 
        rt.title_id, rt.title, rt.production_year
),
CastInfo AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keywords,
    ci.actor_count
FROM 
    TopMovies tm
LEFT JOIN 
    CastInfo ci ON tm.title_id = ci.movie_id
WHERE 
    tm.production_year >= 2000
ORDER BY 
    tm.production_year DESC, ci.actor_count DESC;
