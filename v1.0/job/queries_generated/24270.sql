WITH ActorInfo AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(ci.movie_id) AS total_movies,
        AVG(CASE WHEN t.production_year IS NOT NULL THEN t.production_year ELSE 0 END) AS avg_production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.person_id, a.name
),

CompanyMovieData AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(cm.company_name, 'Unknown Company') AS company_name,
        STRING_AGG(DISTINCT ct.kind, ', ') FILTER (WHERE ct.kind IS NOT NULL) AS company_types,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cm ON mc.company_id = cm.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, cm.company_name
),

RankedMovies AS (
    SELECT 
        movie_id,
        title,
        company_name,
        company_types,
        cast_count,
        ROW_NUMBER() OVER (PARTITION BY company_name ORDER BY cast_count DESC) AS rank_within_company
    FROM 
        CompanyMovieData
),

TopMovies AS (
    SELECT 
        DISTINCT movie_id,
        title,
        company_name,
        company_types,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank_within_company <= 5
)

SELECT 
    ai.name AS actor_name,
    ai.total_movies,
    ai.avg_production_year,
    ai.keywords,
    tm.title AS top_movie_title,
    tm.company_name AS top_movie_company,
    tm.cast_count AS top_movie_cast_count
FROM 
    ActorInfo ai
LEFT JOIN 
    TopMovies tm ON ai.total_movies > 0 AND EXISTS (
        SELECT 1 FROM cast_info ci WHERE ci.person_id = ai.person_id AND ci.movie_id = tm.movie_id
    )
ORDER BY 
    ai.total_movies DESC, ai.avg_production_year ASC NULLS LAST;

WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level
    FROM 
        aka_title m WHERE m.production_year = (SELECT MAX(production_year) FROM aka_title)
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3
)
SELECT * FROM MovieHierarchy;
