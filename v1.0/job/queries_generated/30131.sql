WITH RECURSIVE GenreHierarchy AS (
    SELECT 
        k.id AS keyword_id,
        k.keyword,
        1 AS level,
        k.phonetic_code
    FROM 
        keyword k
    WHERE 
        k.keyword IS NOT NULL
    UNION ALL
    SELECT 
        k.id AS keyword_id,
        CONCAT(gh.keyword, ' > ', k.keyword) AS keyword,
        level + 1,
        k.phonetic_code
    FROM 
        keyword k
    JOIN 
        GenreHierarchy gh ON k.id = gh.keyword_id
),
RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
),
FilteredCast AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(aka.name, ', ') AS actors
    FROM 
        cast_info ci
    JOIN 
        aka_name aka ON ci.person_id = aka.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    f.actors,
    gh.keyword,
    COALESCE(mk.keyword, 'No Keywords') AS keywords,
    COUNT(mk.movie_id) AS keyword_count
FROM 
    RankedTitles rt
LEFT JOIN 
    FilteredCast f ON rt.title_id = f.movie_id
LEFT JOIN 
    movie_keyword mk ON rt.title_id = mk.movie_id
LEFT JOIN 
    GenreHierarchy gh ON mk.keyword_id = gh.keyword_id
WHERE 
    rt.rank <= 5
GROUP BY 
    rt.title, 
    rt.production_year, 
    f.actors, 
    gh.keyword
ORDER BY 
    rt.production_year DESC, 
    rt.title;
