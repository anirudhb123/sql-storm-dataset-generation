WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY t.id) AS avg_with_notes
    FROM 
        aka_title t
    INNER JOIN 
        complete_cast cc ON t.id = cc.movie_id
    INNER JOIN 
        cast_info c ON c.movie_id = t.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'runtime')
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        person_info pi ON c.person_id = pi.person_id
    LEFT JOIN 
        company_name co ON co.id = c.role_id 
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year BETWEEN 1990 AND 2023
    GROUP BY 
        t.id
),
MovieCharacterCounts AS (
    SELECT 
        ca.name AS character_name, 
        COUNT(DISTINCT cc.movie_id) AS movie_count
    FROM 
        char_name ca
    LEFT JOIN 
        complete_cast cc ON ca.id = cc.subject_id
    GROUP BY 
        ca.name
)
SELECT 
    rm.title, 
    rm.production_year, 
    rm.actor_count, 
    mcc.movie_count, 
    rm.avg_with_notes,
    COALESCE(SUM(CASE WHEN mi.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_movie_notes
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCharacterCounts mcc ON rm.title = mcc.character_name
LEFT JOIN 
    movie_info mi ON rm.title = mi.info
GROUP BY 
    rm.title, rm.production_year, rm.actor_count, mcc.movie_count, rm.avg_with_notes
HAVING 
    rm.actor_count > 5
ORDER BY 
    rm.actor_count DESC, rm.production_year DESC;
