
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS companies_involved,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast_size
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = a.id
    LEFT JOIN 
        company_name co ON co.id = mc.company_id
    LEFT JOIN 
        cast_info c ON c.movie_id = a.id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.total_cast,
        rm.companies_involved
    FROM 
        RankedMovies rm
    WHERE rm.rank_by_cast_size <= 5
),
ActorMovies AS (
    SELECT 
        na.name AS actor_name,
        a.title AS movie_title,
        a.production_year,
        COALESCE(mg.info, 'No award info') AS movie_award_info
    FROM 
        aka_name na 
    JOIN 
        cast_info ci ON na.person_id = ci.person_id
    JOIN 
        aka_title a ON ci.movie_id = a.id
    LEFT JOIN 
        movie_info mg ON a.id = mg.movie_id AND mg.info_type_id IN 
        (SELECT id FROM info_type WHERE info = 'Awards' OR info = 'Nominations')
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.companies_involved,
    LISTAGG(DISTINCT am.actor_name, ', ') WITHIN GROUP (ORDER BY am.actor_name) AS top_actors,
    COUNT(DISTINCT am.movie_award_info) AS unique_award_info_count
FROM 
    TopMovies tm
LEFT JOIN 
    ActorMovies am ON tm.movie_title = am.movie_title AND tm.production_year = am.production_year
GROUP BY 
    tm.movie_title, tm.production_year, tm.total_cast, tm.companies_involved
HAVING 
    COUNT(DISTINCT am.actor_name) > 3
UNION ALL
SELECT 
    'Total Casts Without Award Info' AS movie_title,
    NULL AS production_year,
    COUNT(DISTINCT c.person_id) AS total_cast,
    NULL AS companies_involved,
    NULL AS top_actors,
    NULL AS unique_award_info_count
FROM 
    aka_title a 
LEFT JOIN 
    cast_info c ON a.id = c.movie_id
LEFT JOIN 
    movie_info mi ON a.id = mi.movie_id AND mi.info_type_id IN 
    (SELECT id FROM info_type WHERE info = 'Awards' OR info = 'Nominations')
WHERE 
    mi.info IS NULL
AND 
    a.production_year IS NOT NULL;
