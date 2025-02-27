WITH RankedMovies AS (
    SELECT 
        a.title,
        c.person_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY p.info IS NOT NULL DESC, a.production_year DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        person_info p ON c.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'birth_date')
    WHERE 
        a.production_year >= 2000
        AND k.keyword IS NOT NULL
        AND (p.info IS NULL OR p.info LIKE '199%')
),
FilteredTitles AS (
    SELECT 
        title.title,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        title
    JOIN 
        movie_companies mc ON title.id = mc.movie_id
    WHERE 
        title.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
    GROUP BY 
        title.title
)
SELECT 
    rm.title,
    ft.company_count,
    COALESCE(STRING_AGG(k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL), 'No Keywords') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredTitles ft ON rm.title = ft.title
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = rm.title LIMIT 1)
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    rm.rn = 1
GROUP BY 
    rm.title, ft.company_count
ORDER BY 
    ft.company_count DESC, rm.title;
