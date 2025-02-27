WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title, 
        mt.production_year,
        COALESCE(COUNT(ci.id) FILTER (WHERE ci.note IS NULL), 0) AS null_cast_count,
        COALESCE(AVG(mc.info) FILTER (WHERE mc.note IS NOT NULL), 0) AS average_info_rating,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id
    LEFT JOIN (
        SELECT 
            movie_id, 
            AVG(CASE WHEN LENGTH(info) > 20 THEN LENGTH(info) ELSE NULL END) AS info
        FROM 
            movie_info
        GROUP BY 
            movie_id
    ) mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
PopularMovies AS (
    SELECT 
        movie_title,
        production_year,
        null_cast_count,
        average_info_rating,
        RANK() OVER (ORDER BY null_cast_count DESC, production_year ASC) AS popular_rank
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000 AND 
        null_cast_count > 5
),
TitlesInDifferentLanguages AS (
    SELECT 
        nk.keyword,
        at.title,
        rt.role,
        COUNT(DISTINCT ci.person_id) AS unique_role_count
    FROM 
        aka_title at
    INNER JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    INNER JOIN 
        keyword nk ON mk.keyword_id = nk.id
    FULL OUTER JOIN 
        cast_info ci ON at.id = ci.movie_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        nk.keyword, at.title, rt.role
    HAVING 
        COUNT(DISTINCT ci.person_id) > 3
)
SELECT 
    pm.movie_title,
    pm.production_year,
    pm.null_cast_count,
    pm.average_info_rating,
    COALESCE(tdl.keyword, 'No Keywords') AS keywords,
    COALESCE(tdltimt.role, 'No Role') AS role
FROM 
    PopularMovies pm
LEFT JOIN 
    TitlesInDifferentLanguages tdl ON pm.movie_title = tdl.title
LEFT JOIN 
    TitlesInDifferentLanguages tdltimt ON tdl.keyword = tdltimt.keyword
WHERE 
    pm.null_cast_count > (SELECT AVG(null_cast_count) FROM PopularMovies)
ORDER BY 
    pm.popular_rank, pm.production_year DESC;
