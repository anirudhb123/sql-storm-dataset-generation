
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(mi.info, 'N/A') AS movie_info,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('feature', 'movie'))
    GROUP BY 
        t.id, t.title, mi.info
),
PopularMovies AS (
    SELECT 
        movie_id,
        title,
        movie_info,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    pm.title,
    pm.actor_count,
    LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
    MAX(mr.note) AS production_note
FROM 
    PopularMovies pm
LEFT JOIN 
    movie_companies mc ON pm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.imdb_id
LEFT JOIN 
    movie_info mr ON pm.movie_id = mr.movie_id AND mr.info_type_id = (SELECT id FROM info_type WHERE info = 'production note')
GROUP BY 
    pm.movie_id, pm.title, pm.actor_count
HAVING 
    COALESCE(pm.actor_count, 0) > 2
ORDER BY 
    pm.actor_count DESC;
