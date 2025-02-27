WITH RECURSIVE cinema_hierarchy AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        1 AS level
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id

    UNION ALL 

    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ch.level + 1
    FROM 
        movie_companies mc
    JOIN 
        cinema_hierarchy ch ON mc.movie_id = ch.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),

ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(c.person_id) > 1
),

movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    ch.company_name AS production_company,
    ch.company_type AS company_type,
    rm.num_cast AS num_of_cast,
    rm.rank
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keywords mk ON rm.id = mk.movie_id
LEFT JOIN 
    cinema_hierarchy ch ON rm.id = ch.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.num_of_cast DESC;
