WITH MovieStatistics AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(COALESCE(mi.info::numeric, 0)) AS average_rating,
        MAX(mk.keyword) AS top_keyword
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_info mi ON a.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.title, a.production_year
), RankedMovies AS (
    SELECT 
        *, 
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY average_rating DESC) AS rank
    FROM 
        MovieStatistics
)
SELECT 
    rm.title, 
    rm.production_year, 
    rm.actor_count, 
    rm.average_rating, 
    rm.top_keyword
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 3
ORDER BY 
    rm.production_year, rm.average_rating DESC;
