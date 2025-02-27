WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
TopActors AS (
    SELECT 
        k.keyword,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        movie_keyword mk 
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        k.keyword IS NOT NULL
    GROUP BY 
        k.keyword, m.title, m.production_year
),
CollegianMovies AS (
    SELECT 
        m.id, 
        m.title, 
        COUNT(DISTINCT cc.person_id) AS college_actor_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info cc ON m.id = cc.movie_id
    LEFT JOIN 
        person_info pi ON cc.person_id = pi.person_id 
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'College Graduate') 
    GROUP BY 
        m.id, m.title
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(ta.actor_count, 0) AS total_actors,
    COALESCE(cm.college_actor_count, 0) AS college_actors,
    CASE 
        WHEN COALESCE(cm.college_actor_count, 0) > 0 THEN 'Yes'
        ELSE 'No'
    END AS has_college_actors
FROM 
    RankedMovies tm
LEFT JOIN 
    TopActors ta ON tm.title = ta.title AND tm.production_year = ta.production_year
LEFT JOIN 
    CollegianMovies cm ON tm.title = cm.title
WHERE 
    tm.rn <= 5
ORDER BY 
    tm.production_year DESC, total_actors DESC;
