WITH MovieCounts AS (
    SELECT 
        ct.kind AS cast_type,
        COUNT(ci.id) AS total_cast,
        COUNT(DISTINCT ci.person_id) AS unique_persons
    FROM 
        cast_info ci
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        ct.kind
),
MovieYearStats AS (
    SELECT 
        mt.production_year,
        COUNT(mt.id) AS total_movies,
        COUNT(DISTINCT mt.id) AS unique_movies,
        AVG(LENGTH(mt.title)) AS avg_title_length
    FROM 
        aka_title mt
    GROUP BY 
        mt.production_year
),
KeywordStats AS (
    SELECT 
        k.keyword,
        COUNT(mk.movie_id) AS keyword_count
    FROM 
        keyword k
    JOIN 
        movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY 
        k.keyword
    ORDER BY 
        keyword_count DESC
    LIMIT 10
),
TopDirectors AS (
    SELECT 
        an.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name an
    JOIN 
        cast_info ci ON an.person_id = ci.person_id
    JOIN 
        movie_info mi ON ci.movie_id = mi.movie_id
    WHERE 
        ci.person_role_id IN (SELECT id FROM role_type WHERE role LIKE '%Director%')
    GROUP BY 
        an.name
    ORDER BY 
        movie_count DESC
    LIMIT 5
)
SELECT 
    mc.cast_type,
    mc.total_cast,
    mc.unique_persons,
    my.production_year,
    my.total_movies,
    my.unique_movies,
    my.avg_title_length,
    ks.keyword,
    ks.keyword_count,
    td.name AS top_director,
    td.movie_count
FROM 
    MovieCounts mc
JOIN 
    MovieYearStats my ON TRUE
JOIN 
    KeywordStats ks ON TRUE
JOIN 
    TopDirectors td ON TRUE
ORDER BY 
    my.production_year DESC, 
    mc.total_cast DESC, 
    ks.keyword_count DESC;
