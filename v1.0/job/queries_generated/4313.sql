WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
GenreInfo AS (
    SELECT 
        m.id AS movie_id,
        ARRAY_AGG(DISTINCT kt.keyword) AS keywords
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        m.id
)
SELECT 
    r.title,
    r.production_year,
    g.keywords,
    COALESCE(a.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count
FROM 
    RankedMovies r
LEFT JOIN 
    (SELECT 
         ci.person_id,
         ak.name 
     FROM 
         cast_info ci
     JOIN 
         aka_name ak ON ci.person_id = ak.person_id) a ON a.person_id IN (SELECT 
                                                                       DISTINCT ci.person_id 
                                                                   FROM 
                                                                       cast_info ci 
                                                                   WHERE 
                                                                       ci.role_id IN (SELECT id FROM role_type WHERE role LIKE '%actor%'))
LEFT JOIN 
    complete_cast cc ON r.title_id = cc.movie_id
LEFT JOIN 
    GenreInfo g ON g.movie_id = r.title_id
WHERE 
    r.rank <= 5 AND 
    (r.production_year >= 2000 OR r.production_year IS NULL)
GROUP BY 
    r.title, r.production_year, g.keywords, a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 1
ORDER BY 
    r.production_year DESC, COUNT(DISTINCT c.movie_id) DESC;
