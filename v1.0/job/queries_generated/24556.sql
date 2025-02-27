WITH RecursiveCTE AS (
    SELECT 
        a.person_id, 
        a.name AS actor_name, 
        COUNT(DISTINCT c.movie_id) AS movies_count,
        ARRAY_AGG(DISTINCT t.title) AS movie_titles
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL 
        AND NOT (a.name ILIKE '%UNKNOWN%' OR a.name ILIKE '%UNKNOWN ACTOR%')
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
    ORDER BY 
        movies_count DESC
    LIMIT 10
), 
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title
), 
PredicatesCTE AS (
    SELECT 
        p.person_id,
        p.info AS info_text
    FROM 
        person_info p
    WHERE 
        (p.info_type_id IN (SELECT id FROM info_type WHERE info ILIKE '%birth%')) 
        OR 
        (p.info IS NULL)
)
SELECT 
    r.actor_name,
    r.movies_count,
    r.movie_titles,
    mw.movie_id,
    mw.title,
    mw.keywords,
    CASE 
        WHEN EXISTS (SELECT 1 FROM complete_cast cc WHERE cc.movie_id = mw.movie_id AND cc.subject_id = r.person_id) 
        THEN 'Part of complete cast'
        ELSE 'Not part of complete cast'
    END AS cast_status
FROM 
    RecursiveCTE r
LEFT JOIN 
    MoviesWithKeywords mw ON r.movies_count > 7
JOIN 
    PredicatesCTE p ON r.person_id = p.person_id
ORDER BY 
    r.movies_count DESC, mw.title;

