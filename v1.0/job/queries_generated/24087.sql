WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        m.production_year, 
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank 
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        mh.movie_id, 
        mh.movie_title,
        mh.production_year,
        'Related Movie' AS keyword,
        0 AS keyword_rank 
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id 
    WHERE 
        ml.linked_movie_id IS NOT NULL
),
AggregatedData AS (
    SELECT 
        mh.movie_id, 
        mh.movie_title, 
        COUNT(DISTINCT mh.keyword) AS total_keywords,
        AVG(mh.keyword_rank) AS avg_keyword_rank
    FROM 
        MovieHierarchy mh
    GROUP BY 
        mh.movie_id, mh.movie_title
),
TopMovies AS (
    SELECT 
        ad.movie_id,
        ad.movie_title,
        ad.total_keywords,
        ad.avg_keyword_rank,
        RANK() OVER (ORDER BY ad.total_keywords DESC, ad.avg_keyword_rank ASC) AS rank
    FROM 
        AggregatedData ad
)
SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.total_keywords,
    tm.avg_keyword_rank,
    CASE 
        WHEN tm.total_keywords > 5 THEN 'Highly Keyworded'
        WHEN tm.total_keywords BETWEEN 3 AND 5 THEN 'Moderately Keyworded'
        ELSE 'Low Keyworded'
    END AS keyword_category,
    COALESCE(c.name, 'Unknown Company') AS production_company
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank, tm.movie_title ASC;
