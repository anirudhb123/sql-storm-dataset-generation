WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY LENGTH(a.title) DESC) as title_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
),
TopCharacters AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) as movie_count,
        STRING_AGG(DISTINCT (n.name || ' as ' || r.role), ', ') as roles
    FROM 
        cast_info c
    JOIN 
        name n ON c.person_id = n.id
    JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.person_id
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
CombinedResults AS (
    SELECT 
        t.title,
        t.production_year,
        t.keyword,
        tc.movie_count,
        tc.roles
    FROM 
        RankedTitles t
    LEFT JOIN 
        TopCharacters tc ON t.title = ANY(STRING_TO_ARRAY(tc.roles, ', '))
    WHERE 
        t.title_rank <= 10
)
SELECT 
    production_year,
    COUNT(*) as title_count,
    STRING_AGG(DISTINCT title) as titles,
    STRING_AGG(DISTINCT keyword) as keywords,
    SUM(movie_count) as total_movies,
    STRING_AGG(DISTINCT roles) as all_roles
FROM 
    CombinedResults
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
