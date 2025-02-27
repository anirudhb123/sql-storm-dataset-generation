WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(SUM(c.nm_order), 0) AS total_cast,
        RANK() OVER (ORDER BY COALESCE(SUM(c.nm_order), 0) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        (SELECT 
            ca.movie_id,
            COUNT(*) AS nm_order
         FROM 
            cast_info ca
         GROUP BY 
            ca.movie_id) c ON m.id = c.movie_id
    GROUP BY 
        m.id
), MoviesWithDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.total_cast,
        COALESCE(mi.info, 'No Info') AS movie_info,
        ROW_NUMBER() OVER (PARTITION BY rm.movie_id ORDER BY mi.note) AS info_order
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    WHERE 
        rm.total_cast > 1 AND
        (mi.info_type_id IS NULL OR mi.info_type_id NOT IN (SELECT id FROM info_type WHERE info = 'Unreleased'))
),
TopMovies AS (
    SELECT 
        title, 
        total_cast
    FROM 
        MoviesWithDetails
    WHERE 
        rank <= 10
)
SELECT 
    tm.title,
    tm.total_cast,
    CASE 
        WHEN tm.total_cast > 10 THEN 'Popular'
        WHEN tm.total_cast BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Less Known'
    END AS popularity_status,
    COALESCE((SELECT 
                COUNT(*)
              FROM 
                movie_keyword mk 
              JOIN 
                keyword k ON mk.keyword_id = k.id 
              WHERE 
                mk.movie_id = tm.movie_id AND k.keyword LIKE '%Action%'), 0) AS action_keywords,
    NULLIF((
        SELECT 
            AVG(p.info)
        FROM 
            person_info p 
        WHERE 
            p.info_type_id = (SELECT id FROM info_type WHERE info = 'Award') AND 
            p.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = tm.movie_id)
    ), 0) AS average_awards
FROM 
    TopMovies tm
ORDER BY 
    tm.total_cast DESC;
