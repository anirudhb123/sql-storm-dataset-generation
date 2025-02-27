WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY[m.id] AS hierarchy
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000
        
    UNION ALL
    
    SELECT
        t.linked_movie_id,
        t.title,
        t.production_year,
        mh.hierarchy || t.linked_movie_id
    FROM
        movie_link t
    JOIN
        MovieHierarchy mh ON t.movie_id = mh.movie_id
),
MovieStats AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM
        MovieHierarchy mh
    LEFT JOIN
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mh.movie_id, mh.title, mh.production_year
),
YearStats AS (
    SELECT
        production_year,
        COUNT(DISTINCT movie_id) AS total_movies,
        AVG(cast_count) AS avg_cast_size,
        SUM(keyword_count) AS total_keywords
    FROM
        MovieStats
    GROUP BY
        production_year
),
TopYears AS (
    SELECT
        production_year,
        ROW_NUMBER() OVER (ORDER BY total_movies DESC) AS rank
    FROM
        YearStats
)
SELECT
    ys.production_year,
    ys.total_movies,
    ys.avg_cast_size,
    ys.total_keywords,
    CASE 
        WHEN ys.total_movies IS NULL THEN 'No Data'
        WHEN ys.total_movies > 100 THEN 'Active Year'
        ELSE 'Less Active Year'
    END AS activity_level
FROM
    YearStats ys
JOIN
    TopYears ty ON ys.production_year = ty.production_year
WHERE
    ty.rank <= 5
ORDER BY
    ys.production_year DESC;

-- Optional additional filtering for NULL company names in another example scenario
SELECT 
    DISTINCT c.name AS company_name,
    cc.note AS cast_note,
    COALESCE(m.title, 'Untitled') AS movie_title
FROM
    company_name c
LEFT JOIN
    movie_companies mc ON c.id = mc.company_id
LEFT JOIN
    aka_title m ON mc.movie_id = m.id
LEFT JOIN
    cast_info ci ON mc.movie_id = ci.movie_id
WHERE
    c.name IS NULL
    AND ci.note IS NOT NULL
ORDER BY 
    company_name;
