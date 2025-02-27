WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
),
MovieRoles AS (
    SELECT 
        m.movie_id,
        r.role,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        m.movie_id, r.role
),
CombinedInfo AS (
    SELECT 
        t.title, 
        t.production_year,
        SUM(CASE WHEN m.role = 'Actor' THEN m.actor_count ELSE 0 END) AS total_actors,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        RankedMovies t
    LEFT JOIN 
        MovieRoles m ON t.title_id = m.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.title_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.title, t.production_year
),
FinalResults AS (
    SELECT 
        ci.company_id,
        cn.name AS company_name,
        cm.kind AS company_type,
        COUNT(DISTINCT mc.movie_id) AS movie_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type cm ON mc.company_type_id = cm.id
    LEFT JOIN 
        movie_info mi ON mc.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id IS NULL 
        OR mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')
    GROUP BY 
        ci.company_id, cn.name, cm.kind
)
SELECT 
    c.name AS actor_name,
    tm.title, 
    tm.production_year,
    COALESCE(cr.actor_count, 0) AS actor_count,
    fr.company_name,
    fr.company_type,
    fr.movie_count
FROM 
    aka_name c
JOIN 
    cast_info ci ON c.person_id = ci.person_id
JOIN 
    RankedMovies tm ON ci.movie_id = tm.title_id
LEFT JOIN (
    SELECT 
        movie_id,
        SUM(total_actors) AS actor_count
    FROM 
        CombinedInfo
    GROUP BY 
        movie_id
) cr ON tm.title_id = cr.movie_id
LEFT JOIN 
    FinalResults fr ON tm.title_id = fr.movie_id
WHERE 
    c.name IS NOT NULL
ORDER BY 
    tm.production_year DESC, actor_count DESC
LIMIT 100;
