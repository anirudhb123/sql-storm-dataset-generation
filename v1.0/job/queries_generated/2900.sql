WITH TopMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(c.person_id) AS actor_count
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        a.id
    HAVING 
        COUNT(c.person_id) > 5
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT p.name, ', ') AS actors,
        m.info AS additional_info
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        m.movie_id, m.title, m.production_year, m.info
),
RankedMovies AS (
    SELECT 
        md.*, 
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.actor_count DESC) AS rank
    FROM 
        TopMovies md
)
SELECT 
    r.title,
    r.production_year,
    r.actors,
    r.additional_info
FROM 
    RankedMovies r
WHERE 
    r.rank <= 10
ORDER BY 
    r.production_year DESC, r.rank ASC
UNION ALL
SELECT 
    NULL AS title,
    NULL AS production_year,
    'Total Count of Movies' AS actors,
    COUNT(*) AS additional_info
FROM 
    movie_info
WHERE 
    info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Award%')
ORDER BY 
    production_year DESC;
