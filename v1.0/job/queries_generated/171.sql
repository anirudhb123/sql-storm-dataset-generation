WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(cc.id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(cc.id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cc_info.info, 'No additional info available') AS additional_info,
    STRING_AGG(DISTINCT an.name, ', ') AS actors,
    COUNT(DISTINCT kc.keyword) AS num_keywords,
    DENSE_RANK() OVER (ORDER BY tm.total_cast DESC) AS rank_by_cast
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.title = (SELECT title FROM aka_title WHERE id = cc.movie_id)
LEFT JOIN 
    aka_name an ON cc.person_id = an.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = cc.movie_id
LEFT JOIN 
    keyword kc ON kc.id = mk.keyword_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = cc.movie_id
LEFT JOIN 
    info_type it ON it.id = mi.info_type_id
LEFT JOIN 
    role_type rt ON rt.id = cc.person_role_id
LEFT JOIN 
    movie_companies mcomp ON mcomp.movie_id = cc.movie_id
WHERE 
    tm.production_year >= 2000
    AND (rt.role LIKE '%actor%' OR rt.role IS NULL)
GROUP BY 
    tm.title, tm.production_year, cc_info.info
ORDER BY 
    tm.total_cast DESC, tm.production_year ASC;
