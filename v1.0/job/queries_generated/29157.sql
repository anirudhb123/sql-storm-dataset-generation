WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT a.name) AS actors,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name) AS companies_involved
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id
),
ActorStatistics AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT cc.movie_id) AS total_movies,
        COUNT(DISTINCT k.id) AS total_keywords,
        MAX(t.production_year) AS last_movie_year,
        MIN(t.production_year) AS first_movie_year
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    JOIN 
        title t ON cc.movie_id = t.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        a.person_id
),
KeywordPopularity AS (
    SELECT 
        k.keyword,
        COUNT(mk.movie_id) AS movie_count
    FROM 
        keyword k
    JOIN 
        movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY 
        k.keyword
    ORDER BY 
        movie_count DESC
),
Top5Keywords AS (
    SELECT 
        keyword
    FROM 
        KeywordPopularity
    LIMIT 5
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actors,
    md.keywords,
    md.companies_involved,
    as.total_movies AS actor_count,
    as.last_movie_year,
    as.first_movie_year,
    (SELECT STRING_AGG(keyword, ', ') FROM Top5Keywords) AS popular_keywords
FROM 
    MovieDetails md
JOIN 
    ActorStatistics as ON md.actors LIKE '%' || as.person_id || '%'
WHERE 
    md.keywords IS NOT NULL
ORDER BY 
    md.production_year DESC;
