WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS hierarchy_level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.hierarchy_level + 1 AS hierarchy_level
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.hierarchy_level DESC) AS rank_within_year
    FROM 
        MovieHierarchy mh
),
CompanyAndMovie AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS num_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
MovieKeywordInfo AS (
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
    tm.movie_title,
    tm.production_year,
    COALESCE(cmi.num_movies, 0) AS company_count,
    COALESCE(mki.keywords, 'None') AS keywords,
    CASE 
        WHEN tm.production_year < 2000 THEN 'Classic'
        WHEN tm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    COUNT(DISTINCT ci.person_id) AS total_cast_members,
    MAX(n.name) AS director_name -- Assuming a mapping of persons to directors exists
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyAndMovie cmi ON tm.movie_id = cmi.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = tm.movie_id
LEFT JOIN 
    aka_name n ON ci.person_id = n.person_id
LEFT JOIN 
    MovieKeywordInfo mki ON tm.movie_id = mki.movie_id
GROUP BY 
    tm.movie_id, tm.movie_title, tm.production_year, cmi.num_movies, mki.keywords
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    tm.production_year DESC, total_cast_members DESC
LIMIT 50;
