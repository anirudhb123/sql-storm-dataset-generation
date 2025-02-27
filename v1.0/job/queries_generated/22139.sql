WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY tt.count DESC) AS rank_per_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN (
        SELECT 
            movie_id, 
            COUNT(*) AS count 
        FROM 
            movie_info 
        WHERE 
            info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%award%') 
        GROUP BY 
            movie_id
    ) tt ON tt.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
), MovieAwards AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(a.award_count, 0) AS award_count
    FROM 
        RankedMovies m
    LEFT JOIN (
        SELECT 
            movie_id, 
            COUNT(*) AS award_count 
        FROM 
            movie_info 
        WHERE 
            note IS NULL 
            AND info_type_id = (SELECT id FROM info_type WHERE info = 'Award') 
        GROUP BY 
            movie_id
    ) a ON m.movie_id = a.movie_id
), ActorsWithAwards AS (
    SELECT 
        ak.name,
        COUNT(DISTINCT m.movie_id) AS movie_count,
        SUM(COALESCE(ma.award_count, 0)) AS total_awards
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        MovieAwards m ON ci.movie_id = m.movie_id
    LEFT JOIN 
        movie_info ma ON m.movie_id = ma.movie_id
    WHERE 
        ma.info_type_id = (SELECT id FROM info_type WHERE info = 'Award')
    GROUP BY 
        ak.name
)
SELECT 
    name,
    movie_count,
    total_awards,
    CASE 
        WHEN total_awards = 0 THEN 'No awards yet'
        WHEN total_awards > 10 THEN 'Award-winning actor!'
        ELSE 'Actor with potential'
    END AS award_status
FROM 
    ActorsWithAwards
WHERE 
    movie_count > 5
ORDER BY 
    total_awards DESC NULLS LAST, 
    movie_count DESC;
