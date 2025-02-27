WITH MovieStats AS (
    SELECT 
        a.title AS movie_title,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(w.rank) AS average_role_rank
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        (SELECT 
            role_id, ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY rn) AS rank
         FROM 
            (SELECT 
                movie_id, person_role_id AS role_id, 
                ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY nr_order) AS rn
             FROM 
                cast_info) AS ranked_roles
        ) AS w ON c.role_id = w.role_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.title
),
KeywordStats AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
TopMovies AS (
    SELECT 
        ms.movie_title,
        ms.total_cast,
        ms.average_role_rank,
        ks.keywords
    FROM 
        MovieStats ms
    LEFT JOIN 
        KeywordStats ks ON ms.movie_title = (SELECT title FROM aka_title WHERE id IN (SELECT movie_id FROM movie_keyword WHERE keyword_id IN (SELECT id FROM keyword ORDER BY RANDOM() LIMIT 1)))
    WHERE 
        ms.total_cast > 5 AND ms.average_role_rank IS NOT NULL
    ORDER BY 
        ms.average_role_rank DESC
    LIMIT 10
)
SELECT 
    tm.movie_title,
    tm.total_cast,
    COALESCE(tm.keywords, 'No keywords available') AS keywords
FROM 
    TopMovies tm
ORDER BY 
    tm.total_cast DESC;
