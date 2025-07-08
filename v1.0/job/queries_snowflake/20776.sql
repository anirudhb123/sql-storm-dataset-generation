
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ac.actor_count,
        ROW_NUMBER() OVER (PARTITION BY rm.production_year ORDER BY ac.actor_count DESC) AS rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.movie_id = ac.movie_id
    WHERE 
        ac.actor_count IS NOT NULL
)

SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    COALESCE(cn.name, 'Unknown Company') AS company_name,
    LISTAGG(DISTINCT kt.keyword, ', ') WITHIN GROUP (ORDER BY kt.keyword) AS keywords,
    MAX(CASE WHEN it.info = 'summary' THEN mi.info END) AS movie_summary,
    COUNT(mr.linked_movie_id) AS related_movie_count
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    movie_link mr ON tm.movie_id = mr.movie_id
WHERE 
    tm.rank <= 10 
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, cn.name, tm.actor_count
HAVING 
    COUNT(DISTINCT kt.id) > 1 AND tm.actor_count > 5
ORDER BY 
    tm.production_year DESC, tm.actor_count DESC;
