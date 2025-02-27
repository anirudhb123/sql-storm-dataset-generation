WITH MovieDetails AS (
    SELECT 
        a.title,
        a.production_year,
        c.name AS company_name,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        AVG(CASE WHEN ca.note IS NULL THEN 0 ELSE 1 END) AS has_note,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.id
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%movie%')
        AND a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year, c.name
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        company_name,
        actor_count,
        has_note,
        rank
    FROM 
        MovieDetails
    WHERE 
        actor_count > 5
)

SELECT 
    title,
    production_year,
    company_name,
    actor_count,
    has_note
FROM 
    FilteredMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year ASC,
    actor_count DESC;

WITH ActorTitles AS (
    SELECT 
        n.name, 
        t.title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        name n
    JOIN 
        cast_info ci ON n.id = ci.person_id
    JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    JOIN 
        title t ON cc.subject_id = t.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        n.gender = 'F'
    GROUP BY 
        n.name, t.title
)

SELECT 
    name, 
    title, 
    keyword_count
FROM 
    ActorTitles
WHERE 
    keyword_count > 2
ORDER BY 
    name, 
    keyword_count DESC;
