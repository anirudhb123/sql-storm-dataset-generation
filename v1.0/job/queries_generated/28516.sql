WITH MovieData AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year, 
        string_agg(DISTINCT ak.name, ', ') AS aka_names,
        string_agg(DISTINCT k.keyword, ', ') AS keywords,
        string_agg(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT c.id) AS cast_count
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name AS cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info AS c ON cc.subject_id = c.person_id
    LEFT JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    GROUP BY 
        t.id
), 
PopularMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year, 
        aka_names, 
        keywords, 
        cast_count
    FROM 
        MovieData
    WHERE 
        production_year >= 2000
    ORDER BY 
        cast_count DESC
    LIMIT 10
)
SELECT 
    pm.movie_id, 
    pm.movie_title, 
    pm.production_year, 
    pm.aka_names, 
    pm.keywords, 
    pm.cast_count,
    COUNT(pi.id) AS person_info_count
FROM 
    PopularMovies AS pm
LEFT JOIN 
    person_info AS pi ON pi.person_id IN (
        SELECT DISTINCT 
            c.person_id 
        FROM 
            cast_info AS ci
        WHERE 
            ci.movie_id = pm.movie_id
    )
GROUP BY 
    pm.movie_id, pm.movie_title, pm.production_year, pm.aka_names, pm.keywords, pm.cast_count
ORDER BY 
    pm.production_year DESC;
