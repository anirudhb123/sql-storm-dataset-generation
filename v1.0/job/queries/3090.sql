WITH MovieCounts AS (
    SELECT 
        mt.title,
        COUNT(tc.person_id) AS cast_count,
        MIN(m.production_year) AS earliest_year
    FROM 
        aka_title AS mt
    JOIN 
        complete_cast AS cc ON mt.id = cc.movie_id
    JOIN 
        title AS m ON mt.movie_id = m.id
    LEFT JOIN 
        cast_info AS tc ON cc.subject_id = tc.person_id
    GROUP BY 
        mt.title
),
TopMovies AS (
    SELECT 
        title,
        cast_count,
        earliest_year,
        ROW_NUMBER() OVER (PARTITION BY earliest_year ORDER BY cast_count DESC) AS rn
    FROM 
        MovieCounts
    WHERE 
        cast_count >= 5
),
PersonDetails AS (
    SELECT 
        ak.name AS actor_name,
        k.keyword AS role_keyword,
        cc.movie_id
    FROM 
        aka_name AS ak
    JOIN 
        cast_info AS cc ON ak.person_id = cc.person_id
    JOIN 
        movie_keyword AS mk ON cc.movie_id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
)
SELECT 
    tm.title,
    tm.cast_count,
    tm.earliest_year,
    pd.actor_name,
    pd.role_keyword
FROM 
    TopMovies AS tm
LEFT JOIN 
    PersonDetails AS pd ON tm.title = (SELECT title FROM aka_title WHERE movie_id = pd.movie_id LIMIT 1)
WHERE 
    tm.rn <= 3
ORDER BY 
    tm.earliest_year DESC, 
    tm.cast_count DESC;
