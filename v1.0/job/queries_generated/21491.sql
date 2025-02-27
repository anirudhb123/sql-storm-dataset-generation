WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS avg_cast_order,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT k.keyword) AS total_keywords,
        RANK() OVER (PARTITION BY t.production_year ORDER BY AVG(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) DESC) AS rank_by_cast_order
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id, 
        rm.movie_title, 
        rm.avg_cast_order, 
        rm.total_cast, 
        rm.total_keywords
    FROM 
        RankedMovies rm
    WHERE 
        rm.total_cast > 5 AND rm.rank_by_cast_order <= 3
),
RelatedMovies AS (
    SELECT 
        m.movie_id AS related_movie_id,
        ml.linked_movie_id AS linked_movie_id,
        lt.link AS link_type
    FROM 
        movie_link ml
    JOIN 
        FilteredMovies m ON ml.movie_id = m.movie_id
    JOIN 
        link_type lt ON ml.link_type_id = lt.id
)
SELECT 
    fm.movie_title, 
    fm.total_cast, 
    fm.total_keywords, 
    COALESCE(related_movie_id, 'No Related Movie') AS related_movie_id, 
    COUNT(DISTINCT related_movie_id) OVER (PARTITION BY fm.movie_id) AS related_count,
    CASE 
        WHEN fm.total_keywords > 10 THEN 'Highly Tagged'
        WHEN fm.total_keywords BETWEEN 5 AND 10 THEN 'Moderately Tagged'
        ELSE 'Poorly Tagged' 
    END AS tagging_category
FROM 
    FilteredMovies fm
LEFT JOIN 
    RelatedMovies rm ON fm.movie_id = rm.movie_id
ORDER BY 
    fm.total_cast DESC, 
    fm.movie_title;
