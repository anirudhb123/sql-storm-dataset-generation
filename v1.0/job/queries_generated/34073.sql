WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.title,
        mt.production_year,
        mc.company_id,
        1 AS level
    FROM 
        aka_title AS mt
    JOIN 
        movie_companies AS mc ON mt.id = mc.movie_id
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mt.title,
        mt.production_year,
        mc.company_id,
        mh.level + 1
    FROM 
        MovieHierarchy AS mh
    JOIN 
        aka_title AS mt ON mh.company_id = mc.company_id
    JOIN 
        movie_companies AS mc ON mt.id = mc.movie_id
    WHERE 
        mc.company_type_id IS NOT NULL
),

CompanyStats AS (
    SELECT 
        cn.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS total_movies,
        STRING_AGG(DISTINCT mt.title, ', ') AS movies_list
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        aka_title AS mt ON mc.movie_id = mt.id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        cn.name
),

TopDirectors AS (
    SELECT 
        an.name AS director_name,
        COUNT(DISTINCT ci.movie_id) AS released_movies,
        AVG(mt.production_year) AS avg_release_year
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS an ON ci.person_id = an.person_id
    JOIN 
        aka_title AS mt ON ci.movie_id = mt.id
    WHERE 
        ci.role_id = (SELECT id FROM role_type WHERE role = 'director')
    GROUP BY 
        an.name
    ORDER BY 
        released_movies DESC
    LIMIT 5
),

MoviesWithKeywords AS (
    SELECT
        mt.title,
        mt.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        aka_title AS mt
    JOIN 
        movie_keyword AS mk ON mt.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mt.title, mt.production_year
)

SELECT 
    mh.title AS movie_title,
    mh.production_year,
    cs.company_name,
    cs.total_movies,
    t.director_name,
    t.released_movies AS director_movie_count,
    mw.keywords
FROM 
    MovieHierarchy AS mh
LEFT JOIN 
    CompanyStats AS cs ON mh.company_id = cs.company_id
LEFT JOIN 
    TopDirectors AS t ON mh.title = t.director_name
LEFT JOIN 
    MoviesWithKeywords AS mw ON mh.title = mw.title
WHERE 
    cs.total_movies > 10 
    AND (mh.production_year IS NOT NULL OR mh.production_year > 2010)
ORDER BY 
    mh.production_year DESC, cs.total_movies DESC;

