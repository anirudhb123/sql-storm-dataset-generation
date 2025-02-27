WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        1 AS level
    FROM 
        cast_info ci
    WHERE 
        ci.nr_order = 1

    UNION ALL

    SELECT 
        ci.person_id,
        ci.movie_id,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        ActorHierarchy ah ON ci.movie_id = ah.movie_id
    WHERE 
        ci.nr_order > ah.level
),

TitleAndAka AS (
    SELECT 
        at.title,
        ak.name AS aka_name,
        ak.md5sum AS aka_md5
    FROM 
        aka_title at
    LEFT JOIN 
        aka_name ak ON at.id = ak.id
),

MovieWithKeywords AS (
    SELECT 
        mt.movie_id,
        array_agg(mk.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mk.movie_id = mt.movie_id
    GROUP BY 
        mt.movie_id
),

HighestRatedMovies AS (
    SELECT 
        ti.title,
        ti.production_year,
        AVG(r.rating) AS average_rating
    FROM 
        title ti
    LEFT JOIN 
        movie_info mi ON ti.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        (SELECT 
            movie_id, rating FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
        ) r ON ti.id = r.movie_id
    GROUP BY 
        ti.title, ti.production_year
    HAVING 
        AVG(r.rating) IS NOT NULL
    ORDER BY 
        average_rating DESC
    LIMIT 10
)

SELECT 
    ah.person_id,
    COUNT(DISTINCT ah.movie_id) AS movie_count,
    tah.aka_name,
    mkw.keywords,
    hr.average_rating
FROM 
    ActorHierarchy ah
JOIN 
    TitleAndAka tah ON ah.movie_id IN (SELECT movie_id FROM movie_companies mc WHERE mc.company_id IN (SELECT id FROM company_name WHERE country_code = 'USA'))
LEFT JOIN 
    MovieWithKeywords mkw ON ah.movie_id = mkw.movie_id
LEFT JOIN 
    HighestRatedMovies hr ON ah.movie_id IN (SELECT id FROM title WHERE title = hr.title)
GROUP BY 
    ah.person_id, tah.aka_name, mkw.keywords, hr.average_rating
ORDER BY 
    movie_count DESC
LIMIT 20;
