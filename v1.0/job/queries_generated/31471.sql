WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id, 
        m.title, 
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        Title m ON ml.movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
TopRatedMovies AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        AVG(cast.ratings) AS average_rating
    FROM 
        title mt
    JOIN 
        movie_info mi ON mt.id = mi.movie_id
    JOIN 
        (
            SELECT 
                movie_id, 
                COUNT(*) AS ratings
            FROM 
                complete_cast
            WHERE 
                status_id = 1
            GROUP BY 
                movie_id
        ) cast ON mt.id = cast.movie_id
    GROUP BY 
        mt.id
    HAVING 
        AVG(cast.ratings) > 7
),
TopCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        ct.kind <> 'distributor'
    GROUP BY 
        mc.movie_id
    HAVING 
        COUNT(DISTINCT mc.company_id) > 3
),
FinalResults AS (
    SELECT 
        mh.movie_id, 
        mh.title, 
        mh.production_year, 
        tm.average_rating,
        tc.company_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        TopRatedMovies tm ON mh.movie_id = tm.movie_id
    LEFT JOIN 
        TopCompanies tc ON mh.movie_id = tc.movie_id
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    COALESCE(fr.average_rating, 'No Rating') AS average_rating,
    COALESCE(fr.company_count, 0) AS number_of_companies
FROM 
    FinalResults fr
WHERE 
    fr.production_year BETWEEN 2000 AND 2020
ORDER BY 
    fr.average_rating DESC NULLS LAST,
    fr.number_of_companies DESC;

