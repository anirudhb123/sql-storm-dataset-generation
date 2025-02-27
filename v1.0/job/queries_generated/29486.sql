WITH RankedMovies AS (
    SELECT 
        T.id AS movie_id,
        T.title,
        T.production_year,
        COUNT(CI.id) AS cast_count,
        STRING_AGG(CONCAT(AK.name, ' (', R.role, ')'), ', ') AS full_cast,
        K.keyword AS movie_keyword
    FROM 
        aka_title T
    JOIN 
        complete_cast CC ON T.id = CC.movie_id
    JOIN 
        cast_info CI ON CC.subject_id = CI.person_id
    JOIN 
        ak_name AK ON CI.person_id = AK.person_id
    JOIN 
        role_type R ON CI.role_id = R.id
    JOIN 
        movie_keyword MK ON T.id = MK.movie_id
    JOIN 
        keyword K ON MK.keyword_id = K.id
    WHERE 
        T.production_year > 2000
    GROUP BY 
        T.id, K.keyword
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        full_cast,
        movie_keyword,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    TM.title,
    TM.production_year,
    TM.cast_count,
    TM.full_cast,
    TM.movie_keyword
FROM 
    TopMovies TM
WHERE 
    TM.rank <= 10;
This SQL query is designed to benchmark string processing by determining the top 10 movies (from after the year 2000) with the most cast members, displaying the full cast for each movie along with its title, production year, and associated keyword. The query leverages various joins and aggregations to stitch together the necessary information, showcasing the SQL capabilities in handling strings and managing complex relationships across multiple tables.
