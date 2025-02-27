WITH ranked_movies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM aka_title a
    LEFT JOIN cast_info c ON a.id = c.movie_id
    WHERE a.production_year IS NOT NULL
    GROUP BY a.id, a.title, a.production_year
),
top_movies AS (
    SELECT * 
    FROM ranked_movies 
    WHERE year_rank <= 5
),
movie_keywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword m
    JOIN keyword k ON m.keyword_id = k.id
    GROUP BY m.movie_id
),
movie_info_extended AS (
    SELECT 
        m.movie_id,
        MAX(mi.info) AS synopsis, 
        MAX(CASE WHEN it.info LIKE '%rating%' THEN mi.info END) AS rating,
        MAX(CASE WHEN it.info LIKE '%budget%' THEN mi.info END) AS budget
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    JOIN aka_title m ON mi.movie_id = m.id
    GROUP BY m.movie_id
)
SELECT 
    tm.title, 
    tm.production_year,
    tm.cast_count,
    mk.keywords,
    mie.synopsis,
    mie.rating,
    mie.budget
FROM top_movies tm
LEFT JOIN movie_keywords mk ON tm.id = mk.movie_id
LEFT JOIN movie_info_extended mie ON tm.id = mie.movie_id
WHERE 
    tm.production_year >= 2000 AND 
    (mie.rating IS NOT NULL OR mie.budget IS NULL) -- where rating is available or budget is not 
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;

-- Subquery ensuring no keyword should be an empty string
SELECT 
    title.title,
    COUNT(DISTINCT mk.keyword) AS non_empty_keyword_count
FROM aka_title title
JOIN movie_keyword mk ON title.id = mk.movie_id
WHERE mk.keyword <> ''
GROUP BY title.title 
HAVING COUNT(DISTINCT mk.keyword) > 0 
ORDER BY non_empty_keyword_count DESC;

-- Outer join with null logic
SELECT 
    a.id AS aka_id, 
    a.name, 
    COALESCE(b.title, 'No title available') AS movie_title
FROM aka_name a
LEFT JOIN aka_title b ON b.id = a.id
WHERE 
    a.name_pcode_nf IS NULL OR NOT EXISTS (
        SELECT 1 FROM cast_info ci WHERE ci.person_id = a.person_id
    )
ORDER BY a.name;

-- Full outer join demonstrating corner cases
SELECT 
    COALESCE(aka.id, ct.id) AS unique_id,
    ak.name AS aka_name,
    ct.kind AS cast_type
FROM aka_name ak
FULL OUTER JOIN comp_cast_type ct ON ct.id = ak.person_id
WHERE 
    ak.name IS NOT NULL 
    OR ct.kind IS NULL
ORDER BY unique_id;
